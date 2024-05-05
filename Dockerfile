FROM registry.access.redhat.com/ubi8/dotnet-60-runtime:6.0 AS base
WORKDIR /opt/app-root/app
EXPOSE 80

ENV _BUILDAH_STARTED_IN_USERNS="" \
    BUILDAH_ISOLATION=chroot \
    STORAGE_driver=vfs

RUN usermod --add-subuids 100000-165535 default && \
    usermod --add-subgids 100000-165535 default && \
    setcap cap_setuid+eip /usr/bin/newuidmap && \
    setcap cap_setgid+eip /usr/bin/newgidmap


FROM registry.access.redhat.com/ubi8/dotnet-60:6.0 AS build
RUN curl -L https://raw.githubusercontent.com/Microsoft/artifacts-credprovider/master/helpers/installcredprovider.sh  | sh

ENV ASPNETCORE_ENVIRONMENT "OPENSHIFT"
WORKDIR /opt/app-root/src


RUN dotnet restore "DotNet.Docker.csproj"
WORKDIR /opt/app-root/src
RUN dotnet build "DotNet.Docker.csproj" -c Release -o /opt/app-root/app/build

FROM build AS publish
RUN dotnet publish "DotNet.Docker.csproj" -c Release -o /opt/app-root/app/publish

FROM base AS final
ENV ASPNETCORE_ENVIRONMENT "OPENSHIFT"
WORKDIR /opt/app-root/app
COPY --from=publish /opt/app-root/app/publish .

ENTRYPOINT ["dotnet", "DotNet.Docker.dll"]
