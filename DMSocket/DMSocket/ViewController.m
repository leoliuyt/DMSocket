//
//  ViewController.m
//  DMSocket
//
//  Created by lbq on 2017/9/12.
//  Copyright © 2017年 lbq. All rights reserved.
//

#import "ViewController.h"
#import <CFNetwork/CFNetwork.h>
#import <arpa/inet.h>
#import <fcntl.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <netinet/in.h>
#import <net/if.h>
#import <sys/socket.h>
#import <sys/types.h>
#import <sys/ioctl.h>
#import <sys/poll.h>
#import <sys/uio.h>
#import <sys/un.h>
#import <unistd.h>

static NSInteger kPort = 4321;
static NSInteger kMaxLine = 4096;

@interface ViewController ()

@property (nonatomic, assign) NSInteger port;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /*
     domain：即协议域，又称为协议族（family）。常用的协议族有，AF_INET、AF_INET6、AF_LOCAL（或称AF_UNIX，Unix域socket）、AF_ROUTE等等。协议族决定了socket的地址类型，在通信中必须采用对应的地址，如AF_INET决定了要用ipv4地址（32位的）与端口号（16位的）的组合、AF_UNIX决定了要用一个绝对路径名作为地址。
     type：指定socket类型。常用的socket类型有，SOCK_STREAM、SOCK_DGRAM、SOCK_RAW、SOCK_PACKET、SOCK_SEQPACKET等等（socket的类型有哪些？）。
     protocol：故名思意，就是指定协议。常用的协议有，IPPROTO_TCP、IPPTOTO_UDP、IPPROTO_SCTP、IPPROTO_TIPC等
     
     
     当我们调用socket创建一个socket时，返回的socket描述字它存在于协议族（address family，AF_XXX）空间中，但没有一个具体的地址。如果想要给它赋值一个地址，就必须调用bind()函数，否则就当调用connect()、listen()时系统会自动随机分配一个端口。
     */
    int listenfd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (listenfd == -1) {
        NSLog(@"create socket error:%s errno:%tu",strerror(errno),errno);
        return;
    }
    
    
    /*
     
     sockfd：即socket描述字，它是通过socket()函数创建了，唯一标识一个socket。bind()函数就是将给这个描述字绑定一个名字。
     addr：一个const struct sockaddr *指针，指向要绑定给sockfd的协议地址。这个地址结构根据地址创建socket时的地址协议族的不同而不同
     */
    
    struct sockaddr_in serveraddr;
    memset(&serveraddr, 0, sizeof(serveraddr));
    serveraddr.sin_family = AF_INET;
    serveraddr.sin_addr.s_addr = htonl(INADDR_ANY);
    serveraddr.sin_port = htons(kPort);
    
    int bindResult = bind(listenfd, (struct sockaddr*)&serveraddr, sizeof(serveraddr));
    if (bindResult == -1) {
        NSLog(@"bind socket error:%s(error:%d)",strerror(errno),errno);
        return;
    }
    
    int listenResult = listen(listenfd, 10);
    if(listenResult == -1){
        NSLog(@"listen socket error: %s(errno: %d)\n",strerror(errno),errno);
        return;
    }
    
    NSLog(@"waiting for client's request");
    
    char    buff[4096];
    ssize_t n;
    while (1) {
        struct sockaddr_in addr;
        socklen_t addrLen = sizeof(addr);
        int acceptResult = accept(listenfd, (struct sockaddr*)&addr, &addrLen);
        NSLog(@"acceptResult = %tu",acceptResult);
        if (acceptResult == -1) {
            NSLog(@"accept socket error: %s(errno: %d)",strerror(errno),errno);
            continue;
        }
        
        //子socket的地址数据
        NSData *addData = [NSData dataWithBytes:&addr length:addrLen];
        
        n = recv(acceptResult, buff, kMaxLine, 0);
        buff[n] = '\0';
        printf("recv msg from client: %s\n", buff);
//        close(acceptResult);
        // Prevent SIGPIPE signals
        
        int nosigpipe = 1;
        //防止错误信号导致进程关闭
        setsockopt(acceptResult, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe, sizeof(nosigpipe));
    }
    
//    close(listenfd);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
