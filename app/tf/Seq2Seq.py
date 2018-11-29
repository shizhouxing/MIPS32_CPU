import tensorflow as tf
import numpy as np
import os
from tensorflow.python.layers.core import Dense
from helper import GreedyEmbeddingHelper

UNK_ID, PAD_ID, EOS_ID, GO_ID = 0, 1, 2, 3

class Seq2Seq():
    def __init__(self, sess, FLAGS, embed):
        self.sess = sess
        self.vocab_size = len(embed)
        self.dim_embed_word = FLAGS.dim_embed_word
        self.num_units = FLAGS.num_units        
        self.learning_rate = tf.Variable(FLAGS.learning_rate, trainable=False, dtype=tf.float32)
        self.learning_rate_decay_op = self.learning_rate.assign(
            self.learning_rate * FLAGS.learning_rate_decay)        
        self.optimizer = tf.train.GradientDescentOptimizer(self.learning_rate)      
        
        with tf.variable_scope("seq2seq"):        
            self._build_embedding(embed)
            self._build_input()
            self._build_encoder()
            self._build_decoder()        
        
    def _build_embedding(self, embed):
        self.symbol2index = tf.contrib.lookup.MutableHashTable(
            key_dtype=tf.string,
            value_dtype=tf.int64,
            default_value=UNK_ID,
            shared_name="in_table",
            name="in_table",
            checkpoint=True)
        self.index2symbol = tf.contrib.lookup.MutableHashTable(
            key_dtype=tf.int64,
            value_dtype=tf.string,
            default_value="UNK",
            shared_name="out_table",
            name="out_table",
            checkpoint=True)
        self.embed = tf.get_variable("word_embedding", dtype=tf.float32, initializer=embed)  
        
    def _build_input(self):
        with tf.variable_scope("input"):
            self.post_string = tf.placeholder(tf.string,(None, None), 'post_string')
            self.response_string = tf.placeholder(tf.string, (None, None), 'response_string')

            self.post = self.symbol2index.lookup(self.post_string)
            self.post_len = tf.placeholder(tf.int32, (None,), 'post_len')
            self.response = self.symbol2index.lookup(self.response_string)
            self.response_len = tf.placeholder(tf.int32, (None,), 'response_len')

            self.batch_size = tf.shape(self.response)[0]
            self.batch_len = tf.shape(self.response)[1]   

            self.input_enc = tf.nn.embedding_lookup(self.embed, self.post)
            self.input_dec = tf.nn.embedding_lookup(self.embed, tf.concat([
                tf.ones((self.batch_size, 1), dtype=tf.int64) * GO_ID,
                tf.split(self.response, [self.batch_len - 1, 1], axis=1)[0]
            ], 1))

    def _build_cell(self):
        return tf.contrib.rnn.GRUCell(self.num_units)

    def _build_encoder(self):
        with tf.variable_scope("encoder"):
            cell = self._build_cell()
            _, self.enc_post = tf.nn.dynamic_rnn(
                cell=cell,
                inputs=self.input_enc,
                sequence_length=self.post_len,
                dtype=tf.float32
            )

    def _build_decoder(self):
        self.output_layer = Dense(self.vocab_size,
            kernel_initializer=tf.truncated_normal_initializer(stddev=0.1))
        with tf.variable_scope("decoder"):
            cell = self._build_cell()
            train_helper = tf.contrib.seq2seq.TrainingHelper(
                inputs=self.input_dec,
                sequence_length=self.response_len
            )
            train_decoder = tf.contrib.seq2seq.BasicDecoder(
                cell=cell,
                helper=train_helper,
                initial_state=self.enc_post,
                output_layer=self.output_layer
            )
            train_output, _, _ = tf.contrib.seq2seq.dynamic_decode(
                decoder=train_decoder
            )
            mask = tf.sequence_mask(self.response_len, self.batch_len, dtype=tf.float32)

            self.loss = tf.contrib.seq2seq.sequence_loss(train_output.rnn_output, self.response, mask) 

            params = tf.trainable_variables()
            gradients = tf.gradients(
                self.loss * \
                tf.cast(tf.reduce_sum(self.response_len), tf.float32) / \
                tf.cast(self.batch_len, tf.float32), params
            ) 
            clipped_gradients, _ = tf.clip_by_global_norm(gradients, 5.0)
            self.train_op = self.optimizer.apply_gradients(zip(clipped_gradients, params))
            self.train_out = self.index2symbol.lookup(tf.cast(train_output.sample_id, tf.int64))
        
        with tf.variable_scope("decoder", reuse=True):
            cell = self._build_cell()
            start_tokens = tf.tile(tf.constant([GO_ID], dtype=tf.int32), [self.batch_size])
            end_token = EOS_ID
            infer_helper = GreedyEmbeddingHelper(
                self.embed,
                start_tokens,
                end_token
            )
            infer_decoder = tf.contrib.seq2seq.BasicDecoder(
                cell=cell,
                helper=infer_helper,
                initial_state=self.enc_post,
                output_layer=self.output_layer
            )
            infer_output, _, _ = tf.contrib.seq2seq.dynamic_decode(
                decoder=infer_decoder,
                maximum_iterations=64
            )
            self.inference = self.index2symbol.lookup(tf.cast(infer_output.sample_id, tf.int64))

    def initialize(self, vocab):
        op_in = self.symbol2index.insert(
            tf.constant(vocab), tf.constant(range(len(vocab)), dtype=tf.int64))
        op_out = self.index2symbol.insert(
            tf.constant(range(len(vocab)), dtype=tf.int64), tf.constant(vocab))
        self.sess.run([op_in, op_out])        

    def format_data(self, data):
        def padding(sent, l):
            return sent + ["EOS"] + ["PAD"] * (l - len(sent) - 1)

        len_post, len_resp = 0, 0
        for pair in data:
            len_post = max(len_post, len(pair["post"]))
            len_resp = max(len_resp, len(pair["resp"]))
        len_post += 1
        len_resp += 1

        post_string, post_len, response_string, response_len = [], [], [], []
        for pair in data:
            post_string.append(padding(pair["post"], len_post))
            post_len.append(len(pair["post"]) + 1)
            response_string.append(padding(pair["resp"], len_resp))            
            response_len.append(len(pair["resp"]) + 1)
    
        return {
            "post_string": np.array(post_string),
            "post_len": np.array(post_len),
            "response_string": np.array(response_string),
            "response_len": np.array(response_len)
        }
    
    def step(self, sess, data, is_train=False, is_infer=False):
        data = self.format_data(data)
        input_feed = {
            self.post_string: data['post_string'],
            self.post_len: data['post_len'],
            self.response_string: data['response_string'],
            self.response_len: data['response_len']
        }
        if is_infer:
            output_feed = self.inference
        else:
            if is_train:
                output_feed = [self.loss, self.inference, self.train_op]
            else:
                output_feed = [self.loss, self.inference]
        return sess.run(output_feed, input_feed)
