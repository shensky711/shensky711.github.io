# Jekyll配置

 1. 安装Ruby，安装时记得勾选选项，把Ruby添加到环境变量，安装完可执行`gem update -- system`进行更新。gem更新由于网络原因会比较慢，可以使用国内的镜像，参考[https://ruby-china.org/topics/29250][1]
 2. 安装DevKit,其实就是把DevKit解压
 3. 在DevKit目录运行：`ruby dk.rb init` 和 `ruby dk.rb install`（确保config.yml文件中路径是否正确，如`- G:/path/to/ruby/`）
 4. 执行`gem install jekyll`
 5. 启动jekyll的local server：`jekyll serve`，build生成静态页面：`jekyll build`

# Gemfile依赖
有些项目有一个Gemfile文件描述项目的依赖，如果不把依赖加载进来，jekyll build会失败，可以通过下面步骤解决

 1. gem install bundler
 2. bundle init
 3. bundle install

通过bundle install安装成功后，再执行`jekyll build`就可以了
 

  [1]: https://ruby-china.org/topics/29250