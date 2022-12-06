# CPEE Time Shifting for Logs

To install the model manager go to the commandline

```bash
 gem install cpee-shifting
 cpee-shifting new shifting
 cd shifting
 ./shifting start
```
The service is by default running on port 9319 (http, localhost). If this port has to be changed (or the
host, or local-only access, ...), modify the file moma.conf and change:

```yaml
 :port: 9250
```

You may also change the directory where the logs are read/stored

```yaml
 :log_dir: /var/www/logs
```
