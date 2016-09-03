read -p "please input log for commit:" log
if [ ! -n "$log" ] ;then
	echo "you have not input log !"  
else
	echo "start deploy blog"
	
	jekyll build
	rm -f _site/deploy.sh
	rm -rf ../deploy_tmp
	cp -r ./_site ../deploy_tmp
	
#	git add --all
#	git commit -m ${log}

	git checkout master
	rm -r ./*
	cp -r ../deploy_tmp/* ./
#	git add --all
#	git commit -m $(log)
	
	echo "deploy succeed"
fi