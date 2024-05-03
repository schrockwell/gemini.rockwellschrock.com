#! /bin/bash

./generate.rb

rsync -avH _capsule/* gemini:public/
