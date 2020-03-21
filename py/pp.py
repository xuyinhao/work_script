#!/usr/bin/python
with open(filelist,'r') as f:
            lines = f.readlines()
            thr = 10 if len(lines)>10 else len(lines)
            try:
                p = multiprocessing.Pool(thr)
                for i in range(thr):
#                     threading.Thread(target=check_file,args=(lines[i::thr],),name="thread-"+str(i)).start()
                     p.apply_async(check_file,args=(lines[i::thr],))
                p.close()
                p.join()
            except KeyboardInterrupt:
                print "Caught KeyboardInterrupt, terminating workers!"
                p.terminate()
                p.join()

