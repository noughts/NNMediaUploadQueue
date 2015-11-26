#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
pod を更新してpushするスクリプトです。
1. コードを変更
2. podspecのバージョン番号を更新
3. commit
4. python update.py
"""

import commands;
import os;



def runCommand( command ):
	print "$ "+ command;
	os.system( command );
	pass


def getVersion():
	import json;
	projectName = os.getcwd().split("/")[-1];
	result_str = commands.getoutput("pod ipc spec %s.podspec" % projectName)
	# print result_str;
	dict = json.loads( result_str );
	# print dict;
	return dict["version"];


version = getVersion();
runCommand( "git tag "+ version );
runCommand( "git push --tags" );
runCommand( "pod repo push noughts --verbose --allow-warnings" );
