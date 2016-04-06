#Install the needed packages
#install.packages("TEST");
#Load packages
#library(TEST);

#Input Parameters from NetLogo?
#Set the seed to a specific value for reproducibility
set.seed(123);
#Anzahl der Männer
numberOfMen <- 10;
#Anzahl der Frauen
numberOfWomen <- 10;

#Disco Dataframe
discoDF <- data.frame("id"=character(0), "name"=character(0), "maxMatches"=numeric(0), "side"=numeric(0), "partnerList"=character(0), "rank"=character(0), stringsAsFactors = FALSE);
#Create the differnet genders
genders <- c("male", "female");
id = 0;
#Create a temporary data frame for the individual
individual <- data.frame("id"=character(1), "name"=character(1), "maxMatches"=numeric(1), "side"=numeric(1), "partnerList"=character(1), "rank"=character(1), stringsAsFactors = FALSE);

#Create for each gender
for(i in 1:length(genders)){
  #the amount of individuals
  tmpLoopCounter <- ifelse(genders[i]=='female', numberOfMen, numberOfWomen);
  #set some values for each individual
  for(j in 1:tmpLoopCounter){
    #increment the id by 1
    id <- id + 1;
    #the the current id to the individual
    individual$id <- id;
    #add an name to the individual which depends on his gender and the id
    individual$name <- paste(c(genders[i],j), collapse="");
    #the individual is monogamic
    individual$maxMatches <- 1;
    #the individual is on the side of his gender
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