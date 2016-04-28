# topology-truck-cookbook 

Extends the Chef Delivery environment so topology.json files can be used to provision and deploy topologies in the acceptance, union, rehearsal, and deliver phases. 

This build cookbook should be customized to suit the needs of the parent project. Using this cookbook can be done outside of Chef Delivery, too. If the parent project is a Chef cookbook, we've detected that and "wrapped" [delivery-truck](https://github.com/chef-cookbooks/delivery-truck). That means it is a dependency, and each of its pipeline phase recipes is included in the appropriate phase recipes in this cookbook. If the parent project is not a cookbook, it's left as an exercise to the reader to customize the recipes as needed for each phase in the pipeline.

## .delivery/config.json

Need examples here. 


## FAQ

### Why blah, blah? 

An answer to the world blahs are.   


