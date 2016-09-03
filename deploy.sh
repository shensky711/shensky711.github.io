#放置静态页面的分支名
BRANCH_SITE=master

#放置jekyll源码的分支名
BRANCH_SOURCE=source

read -p "please input log for commit:" log
if [ ! -n "$log" ] ;then
	echo "you have not input log !"  
else
	echo "deploy start ..."
	
	jekyll build
	rm -f _site/deploy.sh
	rm -rf ../deploy_tmp
	cp -r ./_site ../deploy_tmp
	
	echo "add for source"
	git add --all
	echo "commit for source"
	git commit -m "${log}"

	echo "checkout for master"
	git checkout ${BRANCH_SITE}
	rm -r ./*
	cp -r ../deploy_tmp/* ./
	rm -rf ../deploy_tmp
	echo "add for master"
	git add --all
	echo "commit for master"
	git commit -m "${log}"
	
	git push -u origin ${BRANCH_SITE}
	git push -u origin ${BRANCH_SOURCE}
	
	echo "deploy succeed"
fi