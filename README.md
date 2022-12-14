The script generates 2 server certificate chains and puts them into one `broker-keystore.jks`. 

Results are saved to directory `keystores`.

#### Copy the keystore:
```
cp keystores/broker-keystore.jks $HIVEMQ_HOME/conf/
```

#### Update config.xml:
```
<keystore>
    <path>conf/broker-keystore.jks</path>
    <password>changeme5</password>
    <private-key-password>changeme5</private-key-password>
</keystore>
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