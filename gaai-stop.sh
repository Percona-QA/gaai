#!/bin/bash
# Created by Roel Van de Paar, Percona LLC

ps -ef | grep 'gaai' | grep -vE "grep|vi " | awk '{print $2}' | xargs kill -9
