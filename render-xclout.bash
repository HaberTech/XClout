#!/bin/bash
git clone -b flutter https://${GIT_USERANME}:${GIT_AUTH}@github.com/HaberTech/XClout.git flutter
git clone -b backend https://${GIT_USERANME}:${GIT_AUTH}@github.com/HaberTech/XClout.git backend
ls
cd backend
ls
gunicorn app:app
