# Example to run this: sh shell/deploy_api.sh

echo ' ----- set utc +8 begin  -----'
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
echo "Asia/Shanghai" > /etc/timezone
echo '---- set utc +8 completed ----'

echo '----- db migration begin -----'
bundle exec rake db:migrate
echo '----- db migration completed -----'

echo '----- rm tmp/ ------'
rm -rf /yunlv_api/tmp/

echo '----- start to run rails app via puma ------'
bundle exec rails s -p 3000 -b 0.0.0.0
