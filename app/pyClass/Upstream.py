# -*- coding:utf-8 -*-
# author ranmufei
# date 2017 06 14
# about: it's a action about edit file nginx.conf; and manger nginx upstream
import fileinput

class Upstream(object):
	"""nginx.conf upstream 控制"""
	def __init__(self, path,upstreamName,upstreamHost):
		#super(Upstream, self).__init__()
		#self.arg = arg
		self.path=path
		self.upstreamName=upstreamName
		self.upstreamHost=upstreamHost


	def getAuther(self):
		return 'ranmufei'

	def addStream(self,filename):
		f=file(filename)
		s=f.read()
		f.close()

		try:
			pass
		except Exception, e:
			raise e
		finally:
			pass
	
		return s	

	def readfile(self,filename):
		f=open(filename,'r')
		return f.read()

		

