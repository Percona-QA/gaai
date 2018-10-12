#!/bin/bash
# Created by Roel Van de Paar, Percona LLC

ps -ef | grep 'gaai' | grep -vE "grep|vi |gaai-stop" | awk '{print $2}' | xargs kill -9
