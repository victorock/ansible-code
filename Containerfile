FROM registry.redhat.io/ubi7/ubi-7
LABEL name="ansible-server" \
      vendor="Red Hat" \
      version="7" \
      release="0" \
      run='docker run -d -p 22022:22 --name=ansible-server ansible-server' \
      summary="RHEL7 Ansible Server" \
      description="Ansible Server" 

RUN REPOLIST=ubi-7,ubi-7-optional \
    INSTALL_PKGS="openssh-server podman fuse-overlayfs" && \
    EXCLUDE_PKGS="container-selinux"
    yum -y update-minimal --disablerepo "*" --enablerepo ubi-7 --disableplugin=subscription-manager --setopt=tsflags=nodocs \
      --security --sec-severity=Important --sec-severity=Critical && \
    yum -y install --disablerepo "*" --enablerepo ${REPOLIST} --disableplugin=subscription-manager --setopt=tsflags=nodocs ${INSTALL_PKGS} && \
    yum clean all

RUN useradd ansible; \
  echo ansible:10000:5000 > /etc/subuid; \
  echo ansible:10000:5000 > /etc/subgid;

VOLUME /var/lib/containers
VOLUME /usr/share/ansible
VOLUME /home/ansible

RUN mkdir -p /home/ansible/.local/share/containers /home/ansible/.ssh /home/ansible/.ansible
RUN chown ansible:ansible -R /home/ansible

# Use ConfigMap
ADD https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/containers.conf /etc/containers/containers.conf
ADD https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/podman-containers.conf /home/podman/.config/containers/containers.conf

# chmod containers.conf and adjust storage.conf to enable Fuse storage.
RUN chmod 644 /etc/containers/containers.conf; sed -i -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' /etc/containers/storage.conf
RUN mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers /var/lib/shared/vfs-images /var/lib/shared/vfs-layers; touch /var/lib/shared/overlay-images/images.lock; touch /var/lib/shared/overlay-layers/layers.lock; touch /var/lib/shared/vfs-images/images.lock; touch /var/lib/shared/vfs-layers/layers.lock


USER 10000
EXPOSE 22

CMD ["-D", "-e"]
ENTRYPOINT ["/usr/sbin/sshd"]