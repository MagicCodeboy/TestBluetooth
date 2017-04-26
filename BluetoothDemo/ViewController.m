//
//  ViewController.m
//  BluetoothDemo
//
//  Created by lalala on 2017/4/26.
//  Copyright © 2017年 lsh. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
//蓝牙开发必须遵守的两个协议CBCentralManagerDelegate、CBPeripheralDelegate
@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
//中心管理者
@property(nonatomic,strong) CBCentralManager * cMgr;
//连接到的外设
@property(nonatomic,strong) CBPeripheral * peripheral;

@end

@implementation ViewController
//1.建立一个central manager实例进行蓝牙管理
//懒加载中心管理者
-(CBCentralManager *)cMgr {
    if (!_cMgr) {
        _cMgr = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    }
    return _cMgr;
}
//只要中心管理者初始化 就会触发此代理方法 判断手机蓝牙状态
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case  0:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        case  1:
            NSLog(@"CBManagerStateResetting");
            break;
        case  2:
            NSLog(@"CBManagerStateUnsupported");
            break;
        case  3:
            NSLog(@"CBManagerStateUnauthorized");
            break;
        case  4:
            NSLog(@"CBManagerStatePoweredOff");//蓝牙为开启
            break;
        case  5:
        {
            NSLog(@"CBManagerStatePoweredOn");//蓝牙已开启
            //在中心管理者开启成功后再进行一些操作
            //搜索外设 通过某些服务筛选外设    dict，条件
            [self.cMgr scanForPeripheralsWithServices:nil options:nil];
            //搜索成功之后，会调用我们找到外设的代理方法
            
        }
            break;
        default:
            break;
    }
}
//2.搜索外围设备
//发现外设后的调用的方法
/*
 @param central 中心管理者
 @param peripheral 外设
 @param advertisementData 外设携带的数据
 @param RSSI 外设发出的蓝牙信号强度
 @return nil
 */
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
//    NSLog(@"%s, line = %d, cetral = %@,peripheral = %@, advertisementData = %@, RSSI = %@", __FUNCTION__, __LINE__, central, peripheral, advertisementData, RSSI);
    /*
     <CBCentralManager: 0x170263540>,peripheral = <CBPeripheral: 0x1740e9e00, identifier = 23968F0D-5D9C-4119-A130-608D90FBBE98, name = (null), state = disconnected>, advertisementData = {
     kCBAdvDataIsConnectable = 1;
     }, RSSI = -73
     */
    
    //需要对连接到的外设进行过滤
    // 1.信号强度(40以上才连接, 80以上连接)
    // 2.通过设备名(设备字符串前缀是 OBand（这个是一个手环的前缀）)
    // 在此时我们的过滤规则是:有名字前缀并且信号强度大于35
    // 通过打印,我们知道RSSI一般是带-的
    if ([peripheral.name hasPrefix:@"lalala的iMac"]) {
         //在这里我们可以对 advertisementData(外设携带的广播数据) 进行一些处理
        
        //通常通过过滤 我们会得到一些外设 然后将外设存储到我们的的可变数组中
        //这里由于附近只有一个设备 所以我们先按照1个外设进行处理
        
        //标记我们的外设 让他的生命周期 = vc
        self.peripheral = peripheral;
        //发现完之后就是进行连接
        [self.cMgr connectPeripheral:self.peripheral options:nil];
//        NSLog(@"%s,line = %d",__FUNCTION__,__LINE__);
    }
}

//3.连接外围设备
//中心管理者连接外设成功
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    //连接成功之后 可以进行服务和特征的发现
    
    //设置外设的代理
    self.peripheral.delegate = self;
    
    //外设发现服务，传nil代表不过滤
    //这里会触发外设的代理方法 - (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
    [self.peripheral discoverServices:nil];
}
//外设连接失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"%s, line = %d, %@=连接失败", __FUNCTION__, __LINE__, peripheral.name);
}
//丢失连接
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"%s, line = %d, %@=断开连接", __FUNCTION__, __LINE__, peripheral.name);
}
//4.获得外围设备的服务 & 5.获得服务的特征
//发现外设服务里的特征的时候调用的代理方法（这个是比较重要的方法，你在这里可以通过事先知道的UUID找到你需要的特征，订阅特征，或者这里写入数据给特征也可以）
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    NSLog(@"%s,line = %d",__FUNCTION__,__LINE__);
    for (CBCharacteristic * cha in service.characteristics) {
        NSLog(@"%s,line = %d,char = %@",__FUNCTION__,__LINE__,cha);
    }
}
//6.从外围设备读取数据
//更新特征的value的时候回调用 （凡是从蓝牙传递过来的数据都要经过这个回调。简单的说就是这个方法就是你拿数据的唯一的方法） 你可以判断是否
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"%s,line = %d",__FUNCTION__,__LINE__);
    if ([characteristic  isEqual: @"你要的特征的UUID或者是你已经找到的特征"]) {
        //characteristic.value 就是你要的数据
        [peripheral writeValue:characteristic.value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];

    }
}
//7.给外围设备发送数据（也就是写入数据到蓝牙）
//这个方法可以放在button的相应事件中 也可以在找到特征的时候就写入 具体看你的业务需求怎么用
//[self.peripherale writeValue:_batteryData forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
//第一个参数是已连接的蓝牙设备 ；第二个参数是要写入到哪个特征； 第三个参数是通过此响应记录是否成功写入
//需要注意的是特征的属性是否支持写数据
- (void)yf_peripheral:(CBPeripheral *)peripheral didWriteData:(NSData *)data forCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast                                                = 0x01,
     CBCharacteristicPropertyRead                                                    = 0x02,
     CBCharacteristicPropertyWriteWithoutResponse                                    = 0x04,
     CBCharacteristicPropertyWrite                                                    = 0x08,
     CBCharacteristicPropertyNotify                                                    = 0x10,
     CBCharacteristicPropertyIndicate                                                = 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites                                = 0x40,
     CBCharacteristicPropertyExtendedProperties                                        = 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)        = 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)    = 0x200
     };
     
     打印出特征的权限(characteristic.properties),可以看到有很多种,这是一个NS_OPTIONS的枚举,可以是多个值
     常见的又read,write,noitfy,indicate.知道这几个基本够用了,前俩是读写权限,后俩都是通知,俩不同的通知方式
     */
    //    NSLog(@"%s, line = %d, char.pro = %d", __FUNCTION__, __LINE__, characteristic.properties);
    // 此时由于枚举属性是NS_OPTIONS,所以一个枚举可能对应多个类型,所以判断不能用 = ,而应该用包含&
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self cMgr];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
  
}


@end
