#' This function creates an uni dataframe and writes it into an csv file, which is seperated by ;
#' The picky is uniformly distributed between the pickyLower and pickyUpper value
#'
#' @param seed The seed for the number generator (default: 123)
#' @param numberOfStudents the number of students which should be created (default: 1000) 
#' @param numberOfUniversities the number of Universities, which should be created (default: 4)
#' @param namesOfUniversities (List) the list of the names Universities, which should be created
#' @param collegeCapacity (List) the list of the capacitiers of the universities
#' @param pickyLower value between 0:1; 0 accepts every possible match; 1 accepts none (default: 0)
#' @param pickyUpper value between 0:1; 0 accepts every possible match; 1 accepts none  (default: 0)
#' 
#' How to call it from command line: Rscript initUni.R 123 10 10 0 0

#Add the command Arguments into args
args<-commandArgs(TRUE);

#Install the needed packages
#install.packages("TEST");
#Load packages
#library(TEST);


#Input Parameters from NetLogo?
seed <- ifelse(is.na(args[1]), 123, args[1]);
#Set the seed to a specific value for reproducibility
set.seed(seed);
#Number of Students which should be created
numberOfStudents <- ifelse(is.na(args[2]), 1000, as.integer(args[2]));
#Number of Universities which should be created
numberOfUniversities <- ifelse(is.na(args[3]), 4, as.integer(args[3]));
#Names of the Universities
namesOfUniversities <- ifelse(is.na(args[4]), TRUE , as.list(args[4]));
#TODO generate own list or check the args list
#Capacity of Universities
capacitiesOfUniversities <- ifelse(is.na(args[5]), list(0) , as.list(args[5]));
#TODO generate own list or check the args list
#lower picky value
pickyLower <- ifelse(is.na(args[6]), 0, as.integer(args[4]));
#upper picky value
pickyUpper <- ifelse(is.na(args[7]), 0, as.integer(args[5]));

#Disco Dataframe
discoDF <- data.frame("id"=character(0), "name"=character(0), "maxMatchesInt"=numeric(0), "sideInt"=numeric(0), "partnerList"=character(0), "rankList"=character(0), stringsAsFactors = FALSE);
#Create the differnet genders
genders <- c("male", "female");
id = 0;
#Create a temporary data frame for the individual
individual <- data.frame("id"=character(1), "name"=character(1), "maxMatchesInt"=numeric(1), "sideInt"=numeric(1), "partnerList"=character(1), "rankList"=character(1), stringsAsFactors = FALSE);

#Create for each gender
for(i in 1:length(genders)){
  #the amount of individuals
  tmpLoopCounter <- ifelse(genders[i]=='female', numberOfStudents, numberOfUniversities);
  #set some values for each individual
  for(j in 1:tmpLoopCounter){
    #increment the id by 1
    id <- id + 1;
    #the the current id to the individual
    individual$id <- id;
    #add an name to the individual which depends on his gender and the id
    individual$name <- paste(c(genders[i],j), collapse="");
    #the individual is monogamic
    individual$maxMatchesInt <- 1;
    #the individual is on the side of his gender
    individual$sideInt <- i;
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
  #check how picky this individual is
  picky <- runif(n=1, min=pickyLower, max=pickyUpper);
  #number of other potentials parter to pick
  numberOfPicks <- round(length(notOnMySide$id)*(1-picky));
  #randomly sort the potential partner
  partnerList <- sample(notOnMySide$id,numberOfPicks);
  #splice the list with the picky value
  round(length(partnerList)*picky);
  #collapse them into a string
  stringPartnerList <- paste(partnerList, collapse="#");
  #save the string into the individual partnerList
  discoDF$partnerList[i] <- stringPartnerList;
  #make up ranks for the partnerList
  rankList <- round(runif(length(partnerList)), digits=2);
  #order the rankList desc
  rankList <- sort(rankList, decreasing=TRUE);
  #collapse them into a string
  stringRankList <- paste(rankList, collapse="#");
  #save this into the rank of the individual
  discoDF$rankList[i] <- stringRankList;
}

View(discoDF);
#Write the DF into an csv sep=";"
write.csv2(discoDF, file="disco.csv");