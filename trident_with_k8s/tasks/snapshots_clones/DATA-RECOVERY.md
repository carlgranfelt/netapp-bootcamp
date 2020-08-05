# Data Recovery From Snapshots

Let's pretend you are either having a very bad day or are a malicious user and delete some important data from your application's PV.  Don't forget to use the blog-XXXXXXXX-XXXX pod name for your specific deployment.  You can get this with the `kubectl get -n ghost-snap-clone pod` command.

First, let's check the file is currently there:
```bash
[root@rhel3 ~]# kubectl exec -n ghost-snap-clone blog-5c9c4cdfbf-q986f -- ls -l content/very-important-file.txt
```

Then, let's be evil and delete it:
```bash
[root@rhel3 ~]# kubectl exec -n ghost-snap-clone blog-5c9c4cdfbf-q986f -- rm -f content/very-important-file.txt
```

Finally, let's check to make sure it's gone:


```bash
[root@rhel3 ~]# kubectl exec -n ghost-snap-clone blog-5c9c4cdfbf-q986f -- ls -l content/very-important-file.txt
```

Job done.  Now let's go back to being a good citizen and figure out how you get that data back ASAP!

Developer 1: "Oh no!  Someone has deleted the very important file from my app!"  
Developer 2: "No problem, we can reuse the CSI Snapshot we created earlier without contacting the Infrastructure teams and get it back instantly"

To *restore* data, you'll need to create a read-write clone of the snapshot you want to recover:

```bash
[root@rhel3 ~]# kubectl create -n ghost-snap-clone -f recovery_clone.yaml
persistentvolumeclaim/recovery_clone created
```
...and then, you'll need to patch the object that defines that Application (in our case, a *deployment*) to reference the new `recovery_clone` PV:

```bash
[root@rhel3 ~]# kubectl patch -n ghost-snap-clone deploy blog -p '{"spec":{"template":{"spec":{"volumes":[{"name":"content","persistentVolumeClaim":{"claimName":"recovery-clone"}}]}}}}'
deployment.apps/blog patched
```

That will trigger a new POD creation with the updated configuration:

```bash
[root@rhel3 ~]# kubectl get -n ghost-snap-clone pod
NAME                    READY   STATUS        RESTARTS   AGE
blog-5c9c4cdfbf-q986f   1/1     Terminating   0          5m22s
blog-57cdf6865f-ww2db   1/1     Running       0          6s
```

Now, if you look at the files this POD has access to (the PVC), you will see that the *lost data* (file: content/very-important-file.txt) is back!  *Make sure to reference the new Pod name in this command as the patching process will have recreated a pod and it will restart with a random name.  This pod name changing issue can be remedied by using Statefulsets, but this is a later task in this bootcamp.

```bash
[root@rhel3 ~]# kubectl exec -n ghost-snap-clone blog-57cdf6865f-ww2db -- ls content/very-important-file.txt
-rw-r--r--    1 root     root             0 Jun 30 11:34 content/very-important-file.txt
```

Tadaaa, you have restored your data!  

Keep in mind that some applications may need some extra care once the data is restored (databases for instance).  

## What's next

Once you have finished with this sub-task, head back to the main task to [finish off the other sub-tasks](README.md#e-data-management-with-snapshots).