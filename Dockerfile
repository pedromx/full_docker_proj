#Depending on the operating system of the host machines(s) that will build or run the containers, the image specified in the FROM statement may need to be changed.
#For more information, please see https://aka.ms/containercompat

FROM mcr.microsoft.com/dotnet/core/aspnet:2.2-nanoserver-1809 AS base
WORKDIR /app
EXPOSE 80

#---------TO RUN REACT SIDE -----------
#base image 
FROM node 
#set working directory
RUN mkdir /src/react_app
#copy al files from current directoryto docker
COPY . /src/react_app 

WORKDIR "/src/react_app"

#add '/src/react_app/node_modules/.bin' to $PATH en el caso de que tenga dependencias
ENV PATH /src/react_app/node_modules/.bin:$PATH
 
#install and cache app dependencies
RUN yarn

#Start app
CMD ["npm", "start"]

#---------TO RUN NET CORE SIDE -----------

FROM mcr.microsoft.com/dotnet/core/sdk:2.2-nanoserver-1809 AS build
WORKDIR /src
COPY ["net_core_app/net_core_project.csproj", "net_core_app/"]
RUN dotnet restore "net_core_app/net_core_project.csproj"
COPY . .
WORKDIR "/src/net_core_app"
RUN dotnet build "net_core_project.csproj" -c Release -o /app

FROM build AS publish
RUN dotnet publish "net_core_project.csproj" -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "net_core_project.dll"]
