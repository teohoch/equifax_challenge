# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
if User.count < 1
  User.create!(email: "equifax@demo.cl", password: ENV["DEMO_APP_USER_PASSWORD"])
  seed_user = User.create!(email: "teodoro@hochfarber.com", password: (0...24).map { (65 + rand(26)).chr }.join)

  if Comment.count < 1
    Comment.create!(body: "This terraform deployment is amazing! 10/10 would deploy again!", user: seed_user)
    Comment.create!(body: "Teo is a great coworker! By Totally_not_teo", user: seed_user)
  end
end