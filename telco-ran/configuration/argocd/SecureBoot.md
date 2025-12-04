# Enable and Verify for Secure Boot for SNO

## Enabling Secure Boot

- By default secure boot is enabled when bootmode is selected as UEFISecureBoot as recommended in ClusterInstance.

   ```yaml
    nodes:
    - hostName: "myhost"
      bootMode: "UEFISecureBoot"
   ```

- This value should now be available in the Hub (cluster w/ ACM) cluster's appropriate BareMetalHost (bmh) CR. e.g part of the yaml below

  ```yaml
  spec:
    bootMode: UEFISecureBoot
  ```

## Verifying Secure Boot

1. log into the node

    - With `oc`

      ```shell
      oc debug node/myhost.rh.com
      
      # don't forget to link the logs 
      sh-4.4#  chroot /host
      ```
  
    - **With `ssh` command**

       ```shell
       ssh -i key core@myhost.rh.com # key: private key associated with the node
       ```
  
2. Once logged into the node there are a couple of ways to verify.

    - **With `journalctl`**

      ```shell
      sh-4.4# journalctl -g secureboot
      -- Logs begin at Wed 2022-03-23 17:14:14 UTC, end at Fri 2022-03-25 16:46:26 UTC. --
      Mar 23 17:14:14 localhost kernel: secureboot: Secure boot enabled
      -- Reboot --
      Mar 23 17:20:00 localhost kernel: secureboot: Secure boot enabled
      -- Reboot --
      Mar 23 17:54:41 localhost kernel: secureboot: Secure boot enabled
      -- Reboot --
      Mar 23 18:04:16 localhost kernel: secureboot: Secure boot enabled
      ```

    - **With `mokutil`**

      ```shell
      mokutil --sb-state
      SecureBoot enabled
      ```

**Debugging mokutil**

If you're not using the latest set of source-crs and are running the real-time kernel, `mokutil` may return the following error message:

```shell
mokutil --sb-state
EFI variables are not supported on this system
```

There are multiple ways to enable kernel access to the EFI variables that are required by `mokutil`:

## Update to the latest set of source-cr

  - Append `node-tuning-operator/{x86_64|aarch64}/PerformanceProfile.yaml`'s  `additionalKernelArgs` from PGT

    ```yaml
    spec:
      additionalKernelArgs:
        - ...
        - "efi=runtime"
    ```

or


## Set the Kernel arguement during installation time using ClusterInstance
To do that, create a MachineConfig CR as an example: `99-efi-runtime-path-kargs.yaml`

   ```yaml
   apiVersion: machineconfiguration.openshift.io/v1
   kind: MachineConfig
   metadata:
     labels:
       machineconfiguration.openshift.io/role: master
     name: 99-efi-runtime-path-kargs
   spec:
     kernelArguments:
     - "efi=runtime"
  ```

  2. Include the `MC` with all the other `MC` in the ConfigMapGenerator to include in the configMap that will be referenced back to ClusterInstance via `.spec.extraManifestsRefs`


 ```yaml
  configMapGenerator:
  - files:
    - extra-manifest/01-container-mount-ns-and-kubelet-conf-master.yaml
    - extra-manifest/01-container-mount-ns-and-kubelet-conf-worker.yaml
    - ...........
    - ...........
    - extra-manifest/99-efi-runtime-path-kargs
    name: sno-ran-du-extra-manifest-1
    namespace: <namespace>
  generatorOptions:
    disableNameSuffixHash: true
  ```


## More info on Secure Boot

- [Blog](https://cloud.redhat.com/blog/validating-secure-boot-functionality-in-a-sno-for-openshift-4.9)
