# /!\ Phraseanet Helm charts are now Here /!\ 

https://github.com/alchemy-fr/phraseanet-helm-charts


## Images



## Deploy chart

First you should write your own configuration file named `myvalues.yaml` (see [sample.yaml](./sample.yaml))

```bash
helm install -f myvalues.yaml phraseanet ./all
```

Files named `myvalues.yaml` and `my_values.yaml` are Git ignored

### install

```bash
helm install phraseanet "infra/helm/all" -f "infra/helm/myvalues.yaml" --namespace phraseanet
```

### upgrade

```bash
helm upgrade -f "my_values.yaml" -n phraseanet  phraseanet ./ 
```

### uninstall

```bash
helm uninstall phraseanet --namespace phraseanet 
```



