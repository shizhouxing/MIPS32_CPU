import json, os, re, sys, nltk
import numpy as np

def process_movie():
    print "Processing movie lines..."
    movie_line = {}
    f_lines = open("../data/movie_lines.txt")
    for line in f_lines.readlines():
        split = line.split(" +++$+++ ")
        text = split[-1].lower()
        for i in range(len(text)):
            if not(ord(text[i]) > 0 and ord(text[i]) < 128):
                text = text[:i] + "'" + text[i+1:]
        movie_line[split[0]] = nltk.word_tokenize(text)
        if len(movie_line) % 5000 == 0:
            print "%d lines" % len(movie_line)

    print "Processing movie conversations..."
    pairs = []
    f_conv = open("../data/movie_conversations.txt")
    for dialog in f_conv.readlines():
        turns = json.loads(dialog.split(" +++$+++ ")[-1].replace("'", "\""))
        for i in range(1, len(turns)):
            pairs.append({
                "post": movie_line[turns[i - 1]],
                "resp": movie_line[turns[i]]
            })
            if len(pairs) % 5000 == 0:
                print "%d pairs" % len(pairs)

    h = int(len(pairs) * 0.9)
    f_train = open("../data/train_movie.json", "w")
    f_train.write(json.dumps(pairs[:h]))
    f_train.close()
    f_valid = open("../data/valid_movie.json", "w")
    f_valid.write(json.dumps(pairs[h:]))
    f_valid.close()

def process_convai2():
    def convert(filename_in, filename_out):
        pairs = []
        f_in = open(filename_in)
        inp = f_in.readlines()
        for line in inp:
            t = line.split("\t")
            if len(t) == 1: continue
            if t[0].split()[1:][0] == "__SILENCE__": continue
            pairs.append({
                "post": t[0].split()[1:],
                "resp": t[1].split(),
            })
        f_out = open(filename_out, "w")
        f_out.write(json.dumps(pairs))
        f_out.close()
    convert("../data/train_convai2.txt", "../data/train_convai2.json")
    convert("../data/valid_convai2.txt", "../data/valid_convai2.json")

if sys.argv[1] == 'movie':
    process_movie()
elif sys.argv[1] == 'convai2':
    process_convai2()