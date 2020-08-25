FROM quay.io/iguazio/shell:2.10_b5165_20200718002231

USER root
RUN apt-get update && apt-get install -y \
    openssh-server

RUN mkdir /var/run/sshd
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config 

RUN mkdir -p /igz/.ssh && \
    chmod 0700 /igz/.ssh && \
    chown iguazio:iguazio /igz/.ssh

RUN mkdir -p /root/.ssh && \
    chmod 0700 /root/.ssh

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
