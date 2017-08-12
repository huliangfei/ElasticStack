
##https://www.elastic.co/guide/en/elasticsearch/reference/5.3/docker.html
##Docker部署elasticsearch
##下載鏡像
docker pull docker.elastic.co/elasticsearch/elasticsearch:5.3.0
##開發模式下部署Development modeedit
docker run -p 9200:9200 -e "http.host=0.0.0.0" -e "transport.host=127.0.0.1" docker.elastic.co/elasticsearch/elasticsearch:5.3.0

##production use
##linux
部署elastic前，需求配置虛擬內存參數
增加輸下文件
vi /etc/sysctl.conf
vm.max_map_count=262144
并sysctl -w vm.max_map_count=262144立即生效或重啟系統

掛載主機目錄保存elasticsearch數據時，需要保證目錄有elasticsearch賬號的寫入權限；默認UID為1000:1000
chmod +R 1000:1000 esdata
或者賦予此目錄所有權限 chmod 777 esdata

其他生產環境優化如下：



導入官方beats dashboards模板
下載beats-dashboards-5.3.0.zip模板
在elastic主機上導入dashboard：

在filebeat（或其他beats客戶端上）
cd /usr/share/filebeat/scripts/
./import_dashboards -file beats-dashboads-5.3.1.zip


检查配置filebeat文件是否正确：
cd /usr/share/filebeat/bin/
filebeat --configtest -e


5. 日志过期清理
此命令更新了logstash提供了elasticsearch索引的默认模板，使日志数据会在30天后自动删除。
curl -XPUT localhost:9200/_template/logstash -d '  {  "template": "logstash-*",  "settings": {    "index": {      "refresh_interval": "5s"    }  },  "mappings": {    "_default_": {        "_ttl": {                "enabled": true,                "default": "30d"        },        "dynamic_templates": [        {          "message_field": {            "mapping": {              "index": "analyzed",              "omit_norms": true,              "fielddata": {                "format": "disabled"              },              "type": "string"            },            "match_mapping_type": "string",            "match": "message"          }        },        {          "string_fields": {            "mapping": {              "index": "analyzed",              "omit_norms": true,              "fielddata": {                "format": "disabled"              },              "type": "string",              "fields": {                "raw": {                  "index": "not_analyzed",                  "ignore_above": 256,                  "type": "string"                }              }            },            "match_mapping_type": "string",            "match": "*"          }        }      ],      "properties": {        "@timestamp": {          "type": "date"        },        "geoip": {          "dynamic": true,          "properties": {            "location": {              "type": "geo_point"            },            "longitude": {              "type": "float"            },            "latitude": {              "type": "float"            },            "ip": {              "type": "ip"            }          }        },        "@version": {          "index": "not_analyzed",          "type": "string"        }      },      "_all": {        "enabled": true,        "omit_norms": true      }    }  },  "aliases": {}}  '