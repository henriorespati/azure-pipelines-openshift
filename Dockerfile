FROM registry.access.redhat.com/ubi8/dotnet-60-runtime:6.0 AS base

WORKDIR /opt/app-root/app
EXPOSE 80

FROM registry.access.redhat.com/ubi8/dotnet-60:6.0 AS build
RUN curl -L https://raw.githubusercontent.com/Microsoft/artifacts-credprovider/master/helpers/installcredprovider.sh  | sh

ENV ASPNETCORE_ENVIRONMENT "OPENSHIFT"
WORKDIR /opt/app-root/src

COPY  DotNet.Docker.csproj /opt/app-root/src
RUN dotnet restore "DotNet.Docker.csproj"
COPY  . /opt/app-root/src
WORKDIR /opt/app-root/src
RUN dotnet build "DotNet.Docker.csproj" -c Release -o /opt/app-root/app/build

FROM build AS publish
RUN dotnet publish "DotNet.Docker.csproj" -c Release -o /opt/app-root/app/publish

FROM base AS final
ENV ASPNETCORE_ENVIRONMENT "OPENSHIFT"
WORKDIR /opt/app-root/app
COPY --from=publish /opt/app-root/app/publish .
USER 1001
ENTRYPOINT ["dotnet", "DotNet.Docker.dll"]
