#Install the needed packages
#install.packages("TEST");
#Load packages
#library(TEST);

#Anzahl der Männer
numberOfMen <- 10;
#Anzahl der Frauen
numberOfWomen <- 10;

#Disco Dataframe
discoDF <- data.frame("id"=character(0), "name"=character(0), "maxMatches"=numeric(0), "side"=numeric(0), "partnerList"=character(0), "rank"=character(0), stringsAsFactors = FALSE);

genders <- c("male", "female");
id = 0;
individual <- data.frame("id"=character(1), "name"=character(1), "maxMatches"=numeric(1), "side"=numeric(1), "partnerList"=character(1), "rank"=character(1), stringsAsFactors = FALSE);

#Create for each gender
for(i in 1:length(genders)){
  #the amount of individuals
  tmpLoopCounter <- ifelse(genders[i]=='female', numberOfMen, numberOfWomen);
  for(j in 1:tmpLoopCounter){
    #set some values for each individual
    id <- id + 1;
    individual$id <- id;
    individual$maxMatches <- 1;
    individual$side <- i;
    #add the individual to the discoDF
    discoDF <- rbind(discoDF, individual);
  }
}

#For each of the individuals
for(i in 1:nrow(discoDF)){
  #get the individual
  tmpIndividual <- discoDF[i,];
  #check which individuals are not on its side
  notOnMySide <- discoDF[discoDF$side != tmpIndividual$side,];
  #randomly sort the potential partner
  partnerList <- sample(notOnMySide$id);
  #collapse them into a string
  stringPartnerList <- paste(partnerList, collapse="#");
  #save the string into the individual partnerList
  discoDF$partnerList[i] <- stringPartnerList;
  #make up ranks for the partnerList
  rankList <- round(runif(length(notOnMySide$id)), digits=2);
  #order the rankList desc
  rankList <- sort(rankList, decreasing=TRUE);
  #collapse them into a string
  stringRankList <- paste(rankList, collapse="#");
  #save this into the rank of the individual
  discoDF$rank[i] <- stringRankList;
}

View(discoDF);
#Write the DF into an csv sep=";"
write.csv2(discoDF, file="disco.csv");