# Running code-server (web-based VSCode) as a service

This is related to the requirement specified in <https://jira.iguazeng.com/browse/IG-16072>. The need is to support running vscode in a container that supports the Iguazio ecosystem and enables editing files and coding over the v3io fuse driver.

In general the container uses pretty much the same configuration as the Jupyter service, but instead of installing Jupyter it installs code-server. As basis it uses the code available at: <https://github.com/gashirar/code-server-on-kubernetes>.

## What does the deployment contain

The vscode installation contains the following components:

* A pod running the actual code-server
  * Has the needed mounts to access the Iguazio storage system (+ v3io fuse driver) to access it
  * Contains a set of VSCode extensions that are installed out-of-the-box and provides commonly-used functionality (for example Python extension etc.)
  * Supports Conda environments and allows sharing those environments with other dev platforms that the user may have. For example, Conda envs that are in use in Jupyter should be available in VSCode as well
* The code-server is exposed externally, so the user can access it through a URL such as vscode.\<Iguazio system domain-name\>
  * User must be authenticated in Iguazio in order to access the code-server endpoint

### Docker container

The code-server pod is packaged in a Docker container. This container has the following components already installed on it:

* Based on Ubuntu 18.04 (should consider moving to Iguazio base image, based on Alpine)
* Code-server (VSCode), with the following extensions:
  * Python
  * Kubernetes
  * Markdown all in one
  * Python Docstring generator
  * Indent rainbow
  * Bracket pair colorizer 2
* Python 3.7
* Python packages:
  * pip
  * jupyter
  * pylint
* v3io fuse support (installed by k8s as part of the deployment using flexVolume) Same as in the Jupyter service (and others) - /v3io as root directory for the various containers
* A ~/.kube/config file is generated - this is optional and is done to support the VSCode k8s extension. The extension reads the kube config to figure out what to look at. kubectl knows how to access k8s by default without any configuration, but that's not good enough for the extension
* Conda (actually miniconda) for Python package and env management, including a base env that is exactly the same as the one used in Jupyter. Conda is configured to view Conda environemnts created by the user while using other IDEs (such as Jupyter)

### Helm chart

The following components are installed as part of the Helm chart:

* A deployment containing the code-server Docker image
  * A configmap containing configuration scripts needed for service initialization
* RBAC permissions objects needed - ServiceAccount, Role and RoleBinding
  * The role is copied as-is from the Jupyter role currently in use, and is very limited. It can be modified to include additional permissions if required
* A service exposing the deployment
* External access methods:
  * An Ingress exposing the code-server as an external URL
  * A NodePort exposing the same through the app-cluster nodes using a specific port (you need to specify that you want the NodePort to be deployed)
  
  > ## **Note:** The NodePort is essentially a **security hole** and must never be deployed in production
  >
  > The NodePort is temporary, and is only there since it's easier to overcome some certificate management issues. In the production code this will not remain as an option. It's important to note that the NodePort doesn't go through the Iguazio ingress and therefore doesn't perform any user authentication.

## Deployment steps

To deploy the vscode helm chart, the following steps are needed:

0. You need to have an Iguazio system running. It is recommended to have the system deployed with a `production` certificate, otherwise it will limit the vscode functionality and you will need to use NodePort to access it
   * The reason is that the code-server implementation runs within the browser and uses something called a `service worker` to execute various tasks on the container itself. A service worker can only be activated on a trusted webpage, and if using a `trial` certificate (which is an invalid, self-signed cert) it will not run. The main result would be that you cannot work on Jupyter notebooks, but there will be other issues
1. Build the docker image from the Dockerfile in `docker/Dockerfile`, and tagging it `vscode:latest`. For example using the following command:

    ```bash
    cd docker
    docker build -f Dockerfile -t vscode:latest ./
    ```

2. Modify the values in the `helm-chart/values.yaml` file, providing the namespace where the service is to be deployed (usually `default-tenant`), the Iguazio domain, and the version
   * The `curlIp` parameter is somewhat difficult to obtain. It needs to point at the data-cluster nginx server, and is used to download several executables from there. How to retrieve this information is **TBD**
   * Set the `nodePort.enabled` parameter if you want a NodePort to be created. By default it is not enabled
3. Install the Helm chart provided in `helm-chart/Chart.yaml`, giving it a name per your choosing, for example to name it vscode:

    ```bash
    cd helm-chart
    helm -n default-tenant install vscode ./
    ```

4. Verify that the code-server pod is running (note that your pod name will differ based on your user-name and will have a different random suffix):

    ```bash
    $ kubectl -n default-tenant get pods | grep code-server
    code-server-saarc-d79576dbd-5xmtw                 1/1     Running     0          21h
    ```

5. Once the Helm chart was installed, all the k8s resources needed for the code-server to run are deployed and you can access the code-server through:

* `http://vscode.<Iguazio domain>` - this uses the ingress to access the code-server.  
  To verify the URL of the vscode service, you can perform the following command on the app-cluster node:

  ```bash
  $ kubectl -n default-tenant get ingress vscode
  NAME     HOSTS                                             ADDRESS   PORTS     AGE
  vscode   vscode.default-tenant.app.saarc.iguazio-cd1.com             80, 443   44m
  ```

  The URL appears under the HOSTS column (in this case - `vscode.default-tenant.app..`)
* `http://<app-node IP>:<vscode node-port>` - this uses the NodePort interface to access the service.  
  To retrieve the node-port for the service, perform the following command on the k8s app cluster:

  ```bash
  $ kubectl -n default-tenant get services | grep code-server-nodeport
  code-server-nodeport                                        NodePort    10.194.45.128    <none>        8080:30073/TCP                  21h
  ```

  In this example, the service is exposed through port 30073. Your port will most likely be different.
