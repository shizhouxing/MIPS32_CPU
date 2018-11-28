import tensorflow as tf
import numpy as np
import json, re

FLAGS = tf.flags.FLAGS

def load_data(filename):
    print "Loading data:", filename
    f_in = open(filename)
    inp = f_in.readline()
    data = json.loads(inp)
    for pair in data:
        pair["post"] = pair["post"][:FLAGS.max_sent_len]
        pair["resp"] = pair["resp"][:FLAGS.max_sent_len]
    return data

def build_vocab(data):
    print "Building vocabulary..."
    vocab = {}
    for pair in data:
        for sent in [pair["post"], pair["resp"]]:
            for token in sent:
                if token in vocab:
                    vocab[token] += 1
                else:
                    vocab[token] = 1
    vocab_list = ["UNK", "PAD", "EOS", "GO"] + sorted(vocab, key=vocab.get, reverse=True)

    print("Loading word vectors...")
    vectors = {}
    f_in = open(FLAGS.word_vector)
    for line in f_in:
        line = line.split()
        vectors[line[0]] = map(float, line[1:])
    f_in.close()
    embed = []
    cnt_pretrained = 0
    vocab_list_major = []
    for i, word in enumerate(vocab_list):
        if i > FLAGS.vocab_size and (not word in vectors):
            continue
        if len(vocab_list_major) >= FLAGS.max_vocab_size:
            break
        vocab_list_major.append(word)
        if word in vectors:
            embed.append(vectors[word])
            cnt_pretrained += 1
        else:
            embed.append(np.zeros(FLAGS.dim_embed_word, dtype=np.float32))
            
    embed = np.array(embed, dtype=np.float32)
    print "Pre-trained vectors: %d/%d" % (cnt_pretrained, len(embed))
    return vocab_list_major, embed    