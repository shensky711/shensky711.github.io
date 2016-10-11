---
layout: post
title:  利用keytool、openssl生成证书文件
excerpt: 利用keytool、openssl生成证书文件
---

> 转载请标明出处，本文出自:【HansChen的博客 [http://blog.csdn.net/shensky711](http://blog.csdn.net/shensky711)】

# 用openssl指令逐步生成各个文件

 1. 生成服务器密钥：openssl genrsa -out server_private.key 2048
 2. 从密钥生成公钥（非必须）：openssl rsa -in server_private.key -pubout > server_public.key
 3. 生成证书请求文件，这里会让你输入一堆信息，比如组织名称、个人信息等：openssl req -new -key server_private.key -out server_req.csr
 4. 初始化CA环境
    ```
    mkdir demoCA
    cd demoCA
    mkdir certs crl newcerts
    touch index.txt serial
    echo 00 > serial
    cd ..
    ```

 4. 生成ca密钥：openssl genrsa -out ca.key 2048
 5. 生成ca证书：openssl req -new -x509 -key ca.key -out ca.crt
 6. 用ca对服务器证书请求文件进行签名:openssl ca -in server_req.csr -out server.crt -cert ca.crt -keyfile ca.key -config /usr/ssl/openssl.cnf
 7. 可以把服务端的私钥和已签名的证书合并到一个pkcs12格式的文件：openssl pkcs12 -export -out server.pfx -inkey server_private.key -in server.crt  
 8. 也可以把pkcs12格式转化为java常用的jks格式：keytool -importkeystore -v -srckeystore server.pfx -srcstoretype pkcs12 -srcstorepass 123456 -destkeystore server.jks -deststoretype jks -deststorepass 123456


# 用keytool生成
keytool主要可以帮我们：

 1. 创建一个新的JKS(Java Key Store)文件（里面包含了一个新生成的服务器密钥）
 2. 导出一个CSR(Certificate Signung Request)证书申请文件
 3. 导入一个签名后的证书文件到jks文件中

以下是操作步骤：

 1. 生成新的jks文件：keytool -genkeypair -alias server -keyalg RSA -keystore server.jks
 2. 到出证书请求文件：keytool -certreq -alias server -file server.csr -keystore server.jks
 3. 用ca对请求文件进行签名（ca的生成请参考上面）：openssl ca -in server.csr -out server.crt -cert ca.crt -keyfile ca.key -config demoCA/config/openssl.cnf
 4. 导入已签名的证书到jks：keytool -importcert -alias server -file server.crt -keystore server.jks

这样，我们就得到了一个包含了服务器密钥以及已签名证书的jks文件了

# 最终生成的文件
最终服务端需要用到的文件有：
 1. 服务器私钥
 2. 经过CA签名的证书（包含服务器公钥、基本信息）

客户端需要用到的文件有：
 1. CA的证书（包含了CA的公钥，用以对服务器的证书解密，校验证书真伪）

> 有些服务器配置可以使用私钥+证书合并在一起的文件，如jks或者pkcs12文件，这类文件一般叫key.keystore。客户端使用的ca证书一般称为：truststore


# 遇到的问题
openssl对证书签名的时候有可能报国家、组织、地区需一致的错误，是因为在openssl.cfg中的policy_match里面的前三个都选了match，可以修改optional，修改后就可以了
 
 