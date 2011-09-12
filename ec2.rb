
src 'elb tools' do
  requires 'java'
  source "http://ec2-downloads.s3.amazonaws.com/ElasticLoadBalancing-2009-05-15.zip"
  provides 'elb-create-lb'
  configure {
    shell "set -Ux AWS_ELB_HOME"
  }
  build {}
  install {
    
  }
end