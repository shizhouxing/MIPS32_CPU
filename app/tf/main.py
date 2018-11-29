import tensorflow as tf
import numpy as np
import os, random, time, sys
from Seq2Seq import Seq2Seq
from utils import load_data, build_vocab

if not os.environ.has_key("CUDA_VISIBLE_DEVICES"): 
    os.environ["CUDA_VISIBLE_DEVICES"] = "0"
FLAGS = tf.flags.FLAGS

tf.flags.DEFINE_boolean("is_train", False, "is training")
tf.flags.DEFINE_boolean("run_valid", False, "run inference on valid")
tf.flags.DEFINE_integer("display_interval", 100, "display interval")
tf.flags.DEFINE_string("word_vector", "../../glove/glove.6B.50d.txt", "word vector")
tf.flags.DEFINE_string("model_dir", "./model", "model directory")
tf.flags.DEFINE_string("log_dir", "./log", "log directory")
tf.flags.DEFINE_integer("max_sent_len", 50, "max sentence length")
tf.flags.DEFINE_integer("vocab_size", 1000, "vocabulary size")
tf.flags.DEFINE_integer("max_vocab_size", 5000, "vocabulary size")
tf.flags.DEFINE_integer("dim_embed_word", 50, "dimension of word embedding")
tf.flags.DEFINE_integer("num_units", 64, "number of hidden units")
tf.flags.DEFINE_integer("batch_size", 64, "batch size")
tf.flags.DEFINE_float("learning_rate", 0.2, "learning rate")
tf.flags.DEFINE_float("learning_rate_decay", 0.98, "learning rate decay factor")

if not FLAGS.is_train:
    import nltk

def get_batches(data, batch_size, sort=True):
    batches = []
    for i in range((len(data) + batch_size - 1) / batch_size):
        batches.append(data[i * batch_size : (i + 1) * batch_size])
    return batches

data_train_movie = load_data("../data/train_movie.json")
data_valid_movie = load_data("../data/valid_movie.json")
data_train_convai2 = load_data("../data/train_convai2.json")
data_valid_convai2 = load_data("../data/valid_convai2.json")
data_train = data_train_movie + data_train_convai2
data_valid = data_valid_movie + data_valid_convai2
vocab, embed = build_vocab(data_train)
print "Dataset sizes: %d/%d" % (len(data_train), len(data_valid))

config = tf.ConfigProto()
config.gpu_options.allow_growth = True
sess = tf.Session(config=config)
with sess.as_default():
    seq2seq = Seq2Seq(sess, FLAGS, embed)

    global_step = tf.Variable(0, name="global_step", trainable=False)
    global_step_inc_op = global_step.assign(global_step + 1)    
    epoch = tf.Variable(0, name="epoch", trainable=False)
    epoch_inc_op = epoch.assign(epoch + 1)

    saver = tf.train.Saver(
        write_version=tf.train.SaverDef.V2,
        max_to_keep=None, 
        pad_step_number=True, 
        keep_checkpoint_every_n_hours=1.0
    )        

    if tf.train.get_checkpoint_state(FLAGS.model_dir):
        print "Reading model parameters from %s" % FLAGS.model_dir
        saver.restore(sess, tf.train.latest_checkpoint(FLAGS.model_dir))
    else:
        print "Created model with fresh parameters"
        sess.run(tf.global_variables_initializer())  
        seq2seq.initialize(vocab)          
        
    print "Trainable variables:"
    for var in tf.trainable_variables():
        print var

    train_batches = get_batches(data_train, FLAGS.batch_size)
    valid_batches = get_batches(data_valid, FLAGS.batch_size)

    if FLAGS.is_train:
        train_writer = tf.summary.FileWriter(os.path.join(FLAGS.log_dir, "train"))
        valid_writer = tf.summary.FileWriter(os.path.join(FLAGS.log_dir, "valid"))
        summary_placeholder = tf.placeholder(tf.float32)
        summary_op = tf.summary.scalar("ppl", summary_placeholder)
        
        while True:
            epoch_inc_op.eval()
            
            random.shuffle(train_batches)
            start_time = time.time()
            sum_ppl, summary_steps = 0, 0
            
            for batch in train_batches:
                ops = seq2seq.step(sess, batch, is_train=True)
                sum_ppl += np.exp(ops[0])
                summary_steps += 1
                global_step_inc_op.eval()
                global_step_val = global_step.eval()         
                if global_step_val % FLAGS.display_interval == 0:
                    print "epoch %d, global step %d (%.4fs/step), ppl %.5lf" % (
                        epoch.eval(), global_step_val, 
                        (time.time() - start_time) * 1. / summary_steps,
                        sum_ppl / summary_steps
                    )
                    saver.save(sess, "%s/checkpoint-step" % FLAGS.model_dir, global_step=global_step_val) 

            avg_ppl = sum_ppl / len(train_batches)
            summary = sess.run(summary_op, { summary_placeholder: avg_ppl} )
            train_writer.add_summary(summary, global_step=epoch.eval())
            print "epoch %d (learning rate %.5lf)" % \
                (epoch.eval(), seq2seq.learning_rate.eval())
            print "  train ppl: %.5lf" % avg_ppl
            
            sum_ppl = 0
            for batch in valid_batches:
                ops = seq2seq.step(sess, batch)
                sum_ppl += np.exp(ops[0])
            avg_ppl = sum_ppl / len(valid_batches)
            summary = sess.run(summary_op, { summary_placeholder: avg_ppl} )
            valid_writer.add_summary(summary, global_step=epoch.eval())
            print "  valid ppl: %.5lf" % avg_ppl  

            seq2seq.learning_rate_decay_op.eval()          
            
            saver.save(sess, "%s/checkpoint-epoch" % FLAGS.model_dir, global_step=epoch.eval())                                            
    else:
        if FLAGS.run_valid:
            for batch in valid_batches:
                ops = seq2seq.step(sess, batch)
                for i in range(len(batch)):
                    print " ".join(batch[i]["post"])
                    for w in batch[i]["resp"]:
                        if w in vocab:
                            sys.stdout.write(w + " ")
                        else:
                            sys.stdout.write("UNK ")
                    print
                    res = " ".join(ops[1][i])
                    if res.find("EOS") != -1:
                        res = res[:res.find("EOS")]
                    print res
                    print

        while True:
            post = nltk.word_tokenize(raw_input(">>").lower())
            ops = seq2seq.step(sess, [{"post": post, "resp": []}], is_infer=True)
            resp = " ".join(ops[0])
            if resp.find("EOS") != -1: resp = resp[:resp.find("EOS")]
            print resp
