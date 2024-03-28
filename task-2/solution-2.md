## Initial setup 
Once Minikube was ready for further usage, I tried creating resources using the 'nginx.yaml' file: ```kubectl create -f nginx.yaml```

The requested resources were created, but the pod and deployment were pending (checked with ```kubectl get pods```, ```kubectl get deployments```)

Still, tried accessing the page by running ```minikube service sretest-service``` and received another error:

```❌  Exiting due to SVC_UNREACHABLE: service not available: no running pod for service sretest-service found```

During the investigation, I also tried separating configs for the deployment and service into deployment.yaml and service.yaml, but it didn't bring any results.

## Localizing the issues
Started searching for culprits with ```kubectl get events``` and found the following:

```4m39s       Warning   FailedScheduling    pod/sretest-98b9bddd7-c2jjf    0/1 nodes are available: 1 node(s) didn't match Pod's node affinity/selector. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling..```

Having the error log, moved on with googling and found a thread on StackOverflow where one of the solutions was to remove the node affinity-related code. So I tried removing this part, deleting previously created components:  ```kubectl delete deployment sretest```, ```kubectl delete service sretest-service``` 

I ran the ```kubectl create -f nginx.yaml``` command and found the deployment and pod created, so the root cause was localized.

Upon checking the service with ```minukube service sretest-service```, I was still facing the same error as befire. Consequently, I couldn't access the web page as well.

After that, I went back to the configuration file and wondered if this part was related to the issue:
```selector: app: sretest-service``` because the error log referenced exactly to the absence of the expected ```sretest-service``` name.

## Fixing
I tried changing it to ```sretest``` and it helped, so I was happy to see the Nginx page accessible the first time.

So I tried placing the node affinity-related code back, but the deployment and pod still were not created properly. I googled to know more about ```requiredDuringSchedulingIgnoredDuringExecution``` and decided to check if changing it to ```preferredDuringSchedulingIgnoredDuringExecution``` influences the process, but I just got an error upon trying to create resources from the updated file. After checking the details about node affinity types, it became clear that 'preferred' cannot exist single, and we still need to keep our parameter obligatory so I reverted the change back.

Then, finally, I came to the need to add a label for the node. Checked the current labels with ```kubectl get nodes --show-labels``` and added with ```kubectl label nodes minikube node-role.kubernetes.io/application=sretest```. Double-checked that the label is applied and re-applied 'nginx.yaml'.

Ran ```minikube service sretest-service``` once again, saw success ```🎉  Opening service default/sretest-service in default browser...``` and the Nginx page.

<img  src="https://i.imgur.com/JTVJZdg.jpeg"  width="500"  height="200">

In the end, also double-checked with ChatGPT and Gemini if the applied solution is correct and proper.