#Install the needed packages
#install.packages("TEST");
#Load packages
#library(TEST);

#Anzahl der Männer
numberOfMen <- 10;
#Anzahl der Frauen
numberOfWomen <- 10;

discoDF <- data.frame("id"=character(0), "name"=character(0), "maxMatches"=numeric(0), "side"=numeric(0), "partnerList"=character(0), "rank"=character(0), stringsAsFactors = FALSE);

genders <- c("male", "female");
id = 0;
individual <- data.frame("id"=character(1), "name"=character(1), "maxMatches"=numeric(1), "side"=numeric(1), "partnerList"=character(1), "rank"=character(1), stringsAsFactors = FALSE);

for(i in 1:length(genders)){
  tmpLoopCounter <- ifelse(genders[i]=='female', numberOfMen, numberOfWomen);
  for(j in 1:tmpLoopCounter){
    id <- id + 1;
    individual$id <- id;
    individual$maxMatches <- 1;
    individual$side <- i;
    discoDF <- rbind(discoDF, individual);
  }
}

for(i in 1:nrow(discoDF)){
  tmpIndividual <- discoDF[i,];
  notOnMySide <- discoDF[discoDF$side != tmpIndividual$side,];
  partnerList <- sample(notOnMySide$id);
  stringPartnerList <- paste(partnerList, collapse="#");
  discoDF$partnerList[i] <- stringPartnerList;
  rankList <- round(runif(length(notOnMySide$id)), digits=2);
  stringRankList <- paste(rankList, collapse="#");
  discoDF$rank[i] <- stringRankList;
}


View(discoDF);