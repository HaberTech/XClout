#!/bin/bash
pip install --upgrade pip
git clone -b backend https://${GIT_USERANME}:${GIT_AUTH}@github.com/HaberTech/XClout.git backend
git clone -b flutter https://${GIT_USERANME}:${GIT_AUTH}@github.com/HaberTech/XClout.git backend/flutter
ls
cd backend
pip install -r requirements.txt 
ls
