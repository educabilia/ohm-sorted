require 'test/unit'
require 'ohm/sorted'

class Post < Ohm::Model
  include Ohm::Callbacks
  include Ohm::Sorted

  attribute :order
  attribute :status

  sorted :order, group_by: :status
  sorted :order
end

class SortedTest < Test::Unit::TestCase
  def setup
    Ohm.flush
  end

  def test_sorted_find_returns_sorted_set
    Post.create(status: "draft", order: 1)
    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal Ohm::SortedSet, sorted_set.class
  end

  def test_sorted_find_set_key
    Post.create(status: "draft", order: 1)
    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal "Post:sorted:order:status:draft", sorted_set.key

    sorted_set = Post.sorted_find(:order)
    assert_equal "Post:sorted:order", sorted_set.key
  end

  def test_sorted_find_all
    posts = []
    posts << Post.create(order: 1)
    posts << Post.create(order: 2)
    assert_equal posts, Post.sorted_find(:order).to_a
  end

  def test_sorted_find_order
    post_1 = Post.create(status: "draft", order: 2)
    post_2 = Post.create(status: "draft", order: 3)
    post_3 = Post.create(status: "draft", order: 1)
    sorted_set = Post.sorted_find(:order, status: "draft")

    assert_equal [post_3, post_1, post_2], sorted_set.to_a
  end

  def test_sorted_find_with_limit
    posts = []
    posts << Post.create(order: 1)
    posts << Post.create(order: 2)
    Post.create(status: "draft", order: 3)
    assert_equal posts, Post.sorted_find(:order).limit(2).to_a
  end

  def test_sorted_find_with_offset
    Post.create(order: 1)
    posts = []
    posts << Post.create(order: 2)
    posts << Post.create(order: 3)
    assert_equal posts, Post.sorted_find(:order).offset(1).to_a
  end

  def test_sorted_find_with_range
    posts = []
    posts << Post.create(status: "draft", order: 1)
    posts << Post.create(status: "draft", order: 2)
    posts << Post.create(status: "draft", order: 3)
    posts << Post.create(status: "published", order: 4)
    posts << Post.create(status: "draft", order: 5)
    assert_equal posts.slice(1, 2), Post.sorted_find(:order).range(2..3).to_a
    assert_equal [posts[3]], Post.sorted_find(:order, status: "published").range(2..4).to_a
  end

  def test_sorted_find_first
    Post.create(status: "draft", order: 2)
    post = Post.create(status: "draft", order: 1)
    sorted_set = Post.sorted_find(:order, status: "draft")

    assert_equal post, sorted_set.first
  end

  def test_update
    post_1 = Post.create(status: "draft", order: 1)
    post_2 = Post.create(status: "draft", order: 2)

    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal [post_1, post_2], sorted_set.to_a

    post_1.update(order: 3)

    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal [post_2, post_1], sorted_set.to_a

    post_1.update(status: "published")

    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal [post_2], sorted_set.to_a
    sorted_set = Post.sorted_find(:order, status: "published")
    assert_equal [post_1], sorted_set.to_a
  end

  def test_delete
    post = Post.create(status: "draft", order: 1)
    post.delete

    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal [], sorted_set.to_a
  end

  def test_indexes_nil
    post = Post.create(status: "draft")
    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal [post], sorted_set.to_a
  end

  def test_sorted_find_invalid
    exception_class = if defined?(Ohm::IndexNotFound)
      Ohm::IndexNotFound
    else
      Ohm::Model::IndexNotFound
    end

    Post.create(status: "draft", order: 1)
    assert_raises(exception_class) do
      Post.sorted_find(:foo, status: "draft")
    end

    assert_raises(exception_class) do
      Post.sorted_find(:order, foo: "bar")
    end
  end

  def test_sorted_set_index
    post = Post.create(status: "draft", order: 1)
    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal post, sorted_set[post.id]
  end

  def test_sorted_set_size
    Post.create(status: "draft", order: 1)
    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal 1, sorted_set.size
  end

  def test_sorted_set_empty
    sorted_set = Post.sorted_find(:order)
    assert sorted_set.empty?

    Post.create(order: 1)

    sorted_set = Post.sorted_find(:order)
    assert !sorted_set.empty?
  end
end
