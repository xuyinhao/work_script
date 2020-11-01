## 202007
## 基本介绍
    脚本可以在现有的k8s集群，进行对所有pod去测试所有的svc ip+端口通信测试，并记录测试结果
    文件介绍：
        pod2svcNcTest.sh ： 主要测试脚本程序
        pod2svcLocalcheck.sh ： 当需要并发测试时，需要该脚本（由MUL_RUN=1进行控制，默认=0,则不需要该脚本）
        check_log.sh :   重新分析日志用。基本不用关心这个脚本
## 脚本和环境准备
1.  使用root用户，登录到k8s集群的master节点并放置脚本 pod2svcNcTest.sh, pod2svcLocalcheck.sh
2.  执行脚本的master节点需要安装有sshpass工具（脚本里有判断，如果测试不通过，则终止执行）
3.  集群的密码要保持一样，或者可以先免密（master脚本执行节点到其他节点免密）
4.  所有含有pod的节点，需要安装nc,nsenter测试工具 （脚本里有判断，如果没有则终止执行）

## 快速测试
完成 “脚本和环境准备” 后
1. 修改脚本pod2svcNcTest.sh 里 SSHPASS=onceas 为当前环境实际密码
2. 执行脚本 sh pod2svcNcTest.sh 
3. 测试完成后查看日志 ：/var/log/pod2svc/error.end.log

## 日志说明
- [2020-07-21_22:05:18] error: [1] --- TCPTestInNs  [master84.bocloud.com]: tomcat-85c5bfcccd-ndbnb 8cccbbb8c29b 1124 100.64.199.118 9093 
  
  | 时间 | error记录 | TCP或者UDP协议 | pod测试主机 | pod名称 | pod的id | pod的Pid | 测试的svc Ip | 测试的svc port |

      如果遇到此错误，说明“master84机器上的tomcat-85c5bfcccd-ndbnb无法通信100.64.199.118 9093” 
      可以手工到该机器再执行，再具体分析一下原因
      echo "nc -w 2 -z 100.64.199.118 9093 "|nsenter -n -t 1124 ; echo $?

- oerror: [PASS_RETRY=3] error 开头

    表示这个测试，是经过了多次nc测试导致的失败

- error: NODE CHECK FAIL!!! SKIP. master84.bocloud.com tcp 100.64.1.176 80

    表示master84节点直接测试 nc -w 2 -z 100.64.1.176 80 就无法通信



## 具体使用说明与注意
1.  完成脚本和环境准备后
2.  进入脚本pod2svcNcTest.sh 进行修改“可修改变量”

        
    - SSHPASS=onceas  
    ssh 密码,集群所有节点需要一致，或者自行先免密
    
    - MUL_RUN=0       
    默认为0：由master节点依次对每个pod进行测试与svc的连通信。pod比较少时默认0即可
    如果设置为1：需要pod2svcLocalcheck.sh 脚本和pod2svcNcTest.sh脚本放在同一路径下。每个节点负责测试自己节点的pod与svc的通信。
                    
    - SKIP_NO_EP=1    
    默认为1：检查svc，如果svc没有ep则过滤此svc不进行测试 
    设置为0: 所有含有ip(CLUSTER-IP)的svc都要被测试
                    
    - LOCAL_CHECK_SVC=1
    默认为1：用宿主机节点先判断nc,测试svc是否通信，不通信则不记录该svc.pod不会测试此svc  
    设置为0： 直接进行pod与svc的测试
                         
    - NC_WAIT_TIME=2       
    nc wait time, nc命令测试 时，-w 的超时时间(单位:s)，默认2s即可
    
    - PASS_RETRY=4         
    如果可以nc成功的话，则再继续重复执行该值次数的nc通信测试（即重复进行nc测试）
    
    - SHOW_LOG=1           
    测试过程中打印日志
    
    - DEBUG=0              
    打印debug信息的日志
    
    - NAMESPACE=""      
    定义测试的namespace区间，默认为空，表示测试所有namespace. 或者设置为 default
    如果指定1个namespace，那么测试该namespace下的所有pod，到全局所有svc的连通信。 
                        
    - SKIP_NAMESPACE="foo"    
    过滤掉1个namespace,不测试其pod 和 svc 
    
3.  执行脚本
   sh pod2svcNcTest.sh
4. 等待最终日志产生
   查看与分析日志： 默认位置  /var/log/pod2svc/error.end.log




