BRANCH_NAME = source

.PHONY : deploy
deploy:
ifeq ($(log),)
	@echo "deploy failure, you must input log for deploy, use 'make log=******'"
else
	@echo "start deploy blog"
	git checkout $(BRANCH_NAME)
#	git add -all
#	git commit -m $(log)
#	jekyll build
	rm -f _site/makefile
	cp -r ./_site ../deploy_tmp
	git checkout master
	rm -r ./*
	cp -r ../deploy_tmp/* ./
#	git add -all
#	git commit -m $(log)
	echo "deploy succeed"
endif