###########################
## FIRST INSTALL KUBECTL ##
###########################

INSTALLATION INFORMATION FROM ...
https://kubernetes.io/docs/tasks/tools/install-kubectl/#before-you-begin

RUN
>> sudo snap install kubectl --classic

SEE RESULT
2017-12-18T16:42:28-05:00 INFO cannot auto connect core:core-support-plug to core:core-support: (slot auto-connection), existing connection state "core:core-support-plug core:core-support" in the way
kubectl 1.8.5 from 'canonical' installed

RUN 
>> kubectl cluster-info

SEE RESULT
developer@developer-VirtualBox:~/zcmd$ kubectl cluster-info
Kubernetes master is running at http://localhost:8080

RUN
>> echo "source <(kubectl completion bash)" >> ~/.bashrc

SEE RESULT
nothing shown to terminal; everything went into your .bashrc


###########################
## NEXT INSTALL MINIKUBE ##
###########################

INSTALLATION INFORMATION FROM ...
https://github.com/kubernetes/minikube/releases

RUN
>> curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.24.1/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/

SEE RESULT
 +x minikube && sudo mv minikube /usr/local/bin/
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 39.4M  100 39.4M    0     0  4679k      0  0:00:08  0:00:08 --:--:-- 4357k


#################################
## RUN KUBERNETES VIA MINIKUBE ##
#################################

INFORMATION FROM ...
https://kubernetes.io/docs/getting-started-guides/minikube/

RUN 
>> minikube start

SEE RESULT
Starting local Kubernetes v1.8.0 cluster...
Starting VM...
Downloading Minikube ISO
 140.01 MB / 140.01 MB [============================================] 100.00% 0s
E1218 16:57:24.759450    4052 start.go:150] Error starting host: Error creating host: Error executing step: Running precreate checks.
: VBoxManage not found. Make sure VirtualBox is installed and VBoxManage is in the path.

 Retrying.
E1218 16:57:24.760797    4052 start.go:156] Error starting host:  Error creating host: Error executing step: Running precreate checks.
: VBoxManage not found. Make sure VirtualBox is installed and VBoxManage is in the path
================================================================================
An error has occurred. Would you like to opt in to sending anonymized crash
information to minikube to help prevent future errors?
To opt out of these messages, run the command:
	minikube config set WantReportErrorPrompt false
================================================================================
Please enter your response [Y/n]: 

*** LOOKS LIKE MINIKUBE WANTS A VIRTUAL MACHINE --- INSTALL KVM *** 

#### INSTALL KVM ####
See steps at https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#kvm-driver

>> sudo apt install libvirt-bin qemu-kvm
>> sudo usermod -a -G libvirtd $(whoami)
>> newgrp libvirtd

#### TO START USING THIS DRIVER: minikube start --vm-driver kvm

RUN 
>> minikube start --vm-driver kvm

SEE RESULT
Starting local Kubernetes v1.8.0 cluster...
Starting VM...
WARNING: The kvm driver is now deprecated and support for it will be removed in a future release.
				Please consider switching to the kvm2 driver, which is intended to replace the kvm driver.
				See https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#kvm2-driver for more information.
				To disable this message, run [minikube config set WantShowDriverDeprecationNotification false]
E1218 17:04:56.915334    7843 start.go:150] Error starting host: Error creating new host: Driver "kvm" not found. Do you have the plugin binary "docker-machine-driver-kvm" accessible in your PATH?.

 Retrying.
E1218 17:04:56.915595    7843 start.go:156] Error starting host:  Error creating new host: Driver "kvm" not found. Do you have the plugin binary "docker-machine-driver-kvm" accessible in your PATH?

*** THAT SUCKS!!! Now they tell me? ****

################################################################
############ INSTALLING VBOX ON UBUNTU #########################
################################################################

INFORMATION FROM ...
https://www.virtualbox.org/wiki/Linux_Downloads

RUN
>> ... all sorts of commands then ...
>> sudo apt-get install virtualbox

SEE RESULT
DKMS: install completed.
Setting up virtualbox (5.0.40-dfsg-0ubuntu1.16.04.2) ...
vboxweb.service is a disabled or a static unit, not starting it.
Setting up virtualbox-qt (5.0.40-dfsg-0ubuntu1.16.04.2) ...
Processing triggers for libc-bin (2.23-0ubuntu9) ...
Processing triggers for systemd (229-4ubuntu19) ...
Processing triggers for ureadahead (0.100.0-19) ...

## NOW BACK TO KUBERNETES ##

INFORMATION FROM ...
https://kubernetes.io/docs/getting-started-guides/minikube/

RUN 
>> minikube start

SEE RESULT
Starting local Kubernetes v1.8.0 cluster...
Starting VM...
E1219 11:56:38.690537   16051 start.go:150] Error starting host: Error creating host: Error executing step: Running precreate checks.
: This computer doesn't have VT-X/AMD-v enabled. Enabling it in the BIOS is mandatory.

 Retrying.
E1219 11:56:38.691351   16051 start.go:156] Error starting host:  Error creating host: Error executing step: Running precreate checks.
: This computer doesn't have VT-X/AMD-v enabled. Enabling it in the BIOS is mandatory

*** THAT SUCKS; the VTX is already in use by the existing VM instance and not simulated in the VM!
