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

def dump_header(file):
    file.write("// generated automatically\n")
    file.write(".section .rodata.params\n")
    file.write(".p2align 2\n")

# to convert a float to a 32-bit fixed-point real number in Hex
def float2hex(x): 
    y = int(x * (2 ** 16))
    if abs(y) > 2 ** 31:
        print "Warning: Overflow %.8lf" % x
    if y >= 0:
        return "0x%08x" % y
    else:
        return "-0x%07x" % abs(y)
    
def dump_matrix(file, mat, name):
    file.write(".global %s\n" % name)
    file.write("%s: .long " % name)
    if (len(mat.shape) == 1):
        mat = mat.reshape((mat.shape[0], 1))
    for i in range(mat.shape[0]):
        for j in range(mat.shape[1]):
            file.write(float2hex(mat[i][j]))
            if i + 1 == mat.shape[0] and j + 1 == mat.shape[1]:
                file.write("\n")
                return
            file.write(",")
    file.write("\n")

def dump_vocab(file, vocab):
    file.write(".global vocab\n")
    file.write("vocab: .ascii\"")
    for item in vocab:
        file.write(item)
        file.write("\\0")
    file.write("\"\n")
