The script generates 2 server certificate chains and puts them into one `broker-keystore.jks`. 

Results are saved to directory `keystores`.

#### How to use: 
```
./run.sh
```

#### Copy the keystore:
```
cp keystores/broker-keystore.jks $HIVEMQ_HOME/conf/
```

#### Update config.xml:
```
<tls-tcp-listener>
    <port>8020</port>
    <bind-address>0.0.0.0</bind-address>
    <tls>
        <protocols>
            <protocol>TLSv1.2</protocol>
        </protocols>
        <keystore>
            <path>conf/broker-keystore.jks</path>
            <password>changeme5</password>
            <private-key-password>changeme5</private-key-password>
        </keystore>

        <client-authentication-mode>NONE</client-authentication-mode>
    </tls>
</tls-tcp-listener>
```

#### Update /etc/hosts:
```
127.0.0.1   broker1.hivemq.local
127.0.0.1   broker2.hivemq.local
```

#### Test commands:
```
mqtt pub -t Test -m Hello -i Pubbbie -h broker1.hivemq.local -p 8020 --cafile broker1.hivemq.local.chain.pem -v

mqtt pub -t Test -m Hello -i Pubbbie -h broker2.hivemq.local -p 8020 --cafile broker2.hivemq.local.chain.pem -v
```

Test command works only for the broker1 :/ 

#### Dependencies
For the `./run.sh`:
1. `bash` (GNU bash, version 5.2.12(1)-release (x86_64-apple-darwin22.1.0))
1. `keytool` – comes with Java (Open JDK 11)
1. `openssl` (OpenSSL 3.0.7 1 Nov 2022 (Library: OpenSSL 3.0.7 1 Nov 2022))

For the test:
1. `mqtt` – comes with HiveMQ broker (4.9.1)
1. HiveMQ broker (4.9.1) installed locally
1. `/etc/hosts` updated – see above
