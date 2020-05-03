#!/bin/bash

#Setting variables
filepath=/etc/postfix
server=$(hostname)
confLastLine="$(grep "readme_directory = /usr" $filepath/main.cf)"
emailValidation="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"

#Checking if root user
if [ "$(id -u)" != "0" ]; then
	echo -e "ERROR! Sorry, you are not root. \nERROR! Please run me as root. \nAborting!"
	exit 1
fi

echo -e "\n**This is is for use by OKG Tech Employees only**\n**     If you are not a OKG Tech employee     **\n**           Please exit this script!!         **\n"
echo -e "\nAlright, Let's do this!"
sleep 2
echo -e "Please make sure to enter all information correct, if you made any mistakes, you can start me again."

sleep 5

echo -e "\nOK Human: What is your name?"
read techName

if [ "$techName" = "" ]; then
	echo -e "ERROR! Sorry, you did not enter a real name. \nI am not that dumb... \nERROR! Please enter your real name. \nAborting!"
	exit 1
fi

echo "Hi $techName! I am Posty the Robot. Nice to meet you!"
sleep 3

echo -e "\n$techName, what is your email address? (Don't worry I am not going to share it with anyone, I will use it to send a test email)"
read techEmail

if [[ $techEmail =~ $emailValidation ]] ; then
    echo "Awesome!"
else
    echo -e "ERROR! Your email address appears to be invalid. \nERROR! Please check for spelling mistakes and rerun me again. \nAborting!"
    exit 1
fi

echo "You entered $techEmail. Is this correct? (Yy/Nn)"
read techEmailConf

checkTechEmail(){
    if [[ "$techEmailConf" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      echo "We good!"
    else
      echo -e "Whoopsy! Let's try again. \nWhat is your email address?"
      read techEmail
      echo "You entered $techEmail. Is this correct? (Yy/Nn)"
      read techEmailConf
      checkTechEmail
    fi
}
checkTechEmail

sleep 2

echo "Moving on..."

echo -e "**************************** \n****************************"

sleep 1
echo "What is the new email address? (it is ususally ClientName@domain.us)"
read newEmail

if [[ $newEmail =~ $emailValidation ]] ; then
    echo "Awesome!"
else
    echo -e "ERROR! Your email address appears to be invalid. \nERROR! Please check for spelling mistakes and rerun me again. \nAborting!"
    exit 1
fi

echo "You entered $newEmail. Is this correct? (Yy/Nn)"
read pbxEmailConf

checkPBXEmail(){
    if [[ "$pbxEmailConf" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      echo "We better now!"
    else
      echo "Snap! Let's try again."
      echo "What is the new email address?"
      read newEmail
      echo "You entered $newEmail. Is this correct? (Yy/Nn)"
      read pbxEmailConf
      checkPBXEmail
    fi
}
checkPBXEmail

echo "What is the email server? [press enter to use the default]"
read postmarkServer
if [ "$postmarkServer" = "" ] ; then
    postmarkServer=smtp.postmarkapp.com
    echo "Wonerfull!"
 else
    echo -e "Roger that!"
fi

echo "What is the email server port? [press enter to use the default]"
read postmarkPort
if [ "$postmarkPort" = "" ] ; then
    postmarkServer=587
    echo "Hehe! I won't tell anyone ;)"
 else
    echo -e "Alrighy!"
fi


echo -e "\nWhat is the postfix username?"
read postmarkUser

echo "What is the postfix password? (It's usually the same as the username)"
read postmarkPass

echo -e "Bingo! Let's get to work..."
sleep 2

echo -e "Starting process... \nCopying files to /var/spool/asterisk/backup in case somethine goes wrong..."

cp $filepath/main.cf /tmp/main.cf.bak
cp $filepath/generic /tmp/generic.bak

echo -e "Done copying! \nInstalling dependancies..."

yum -y install postfix mailx cyrus-sasl-plain

echo -e "Done! \nRemoving any old config if there are any..."

rm -rf $filepath/main.cf
rm -rf $filepath/generic

yum -y reinstall postfix

echo -e "Cleanup done! \nPostfix is now set to default. \nWriting username and password to the file..."

echo -e "$postmarkServer $postmarkUser:$postmarkPass" >> $filepath/sasl_passwd

echo "I am now going to hash the password"

postmap hash:$filepath/sasl_passwd

echo -e "Done! \nWriting to conf files"

echo -e "\n#The below is auto generated config using the custom OKG Postmark Script" >> $filepath/main.cf
echo -e "\nsmtp_generic_maps = hash:/etc/postfix/generic" >> $filepath/main.cf
echo -e "\nsmtp_sasl_auth_enable = yes" >> $filepath/main.cf
echo -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" >> $filepath/main.cf
echo -e "smtp_sasl_security_options = noanonymous" >> $filepath/main.cf
echo -e "# Secure channel TLS with exact nexthop name match." >> $filepath/main.cf
echo -e "smtp_tls_security_level = secure" >> $filepath/main.cf
echo -e "smtp_tls_mandatory_protocols = TLSv1.2" >> $filepath/main.cf
echo -e "smtp_tls_mandatory_ciphers = high" >> $filepath/main.cf
echo -e "smtp_tls_secure_cert_match = nexthop" >> $filepath/main.cf
echo -e "smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt" >> $filepath/main.cf
echo -e "relayhost = $postmarkServer:$postmarkPort" >> $filepath/main.cf

echo -e "@$server $newEmail" >> $filepath/generic

echo -e "Done! \nOne more step before restarting..."

postmap $filepath/generic

echo -e "Done! \nRestarting postfix..."

service postfix restart

echo -e "Done! \nSening you an email..."
echo -e "Hi $techName \n \nCongratulations! You just installed the new postmark service! \n\n\nDon't tell your pals that you are friends with Posty the Robot. \nThey will think you are insane, Lol. \n\nHave a nice day!" | mail -s"Hooray! it works!" $techEmail
sleep 1
echo -e "\n$techName, check your email please! \nIt can take up to a minute. \nMake sure to check your spam foolder!"
sleep 3

echo -e "Did you get an email? (Yy/Nn)"
read emailDelivered

if [[ "$emailDelivered" =~ ^([yY][eE][sS]|[yY])$ ]] ; then
    echo "Perfecto Amigo! \nLet's delete the file with the clear text..."
else
    echo -e "No way! No way!"
    sleep 1
    echo -e "You want to tell me I worked so hard and this is not working?"
    sleep 1
    echo -e "\nDAMMIT!!!!!!!!!!!!!!!"
    sleep 2
    echo -e "Alright, I really feel bad for you. \nTry to review the mail log /var/log/maillog \n\nYou can run 'tail /var/log/maillog' \nYou can see that info at the bottom of the Google Doc"
    sleep 2
    echo -e "\nSorry I could not get this done. \nSee you next time. \nGoodbye from Posty the Robot!"
    exit 1
fi

sleep 1

rm -rf $filepath/sasl_passwd

echo -e "Done! \n* \n* \nSee bottom of the Google Doc. \n\n**Make sure you add $newEmail under Voicemail and Notifications** \n\n***TEST IT PLEASE!!!***"
sleep 1

echo -e "\nIt was a pleasure working with you $techName! \Have a nice day! \nGoodbye!"

