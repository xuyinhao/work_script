#!/usr/bin/python
import time
import threadpool  
import random
def sayhello(str):
	print("Hello ",str)
	time.sleep(random.randint(1,10))


name_list =['xiaozi','aa','bb','cc','dd','ee','ff']
if __name__ == "__main__":
	start_time = time.time()
	pool = threadpool.ThreadPool(2) 
	requests = threadpool.makeRequests(sayhello, name_list) 
	[pool.putRequest(req) for req in requests] 
	pool.wait() 
	print '%d second'% (time.time()-start_time)
