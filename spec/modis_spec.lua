local modis = require 'modis'
local redis = require 'redis'

describe('modis', function()
  local db, red
  before_each(function()
    red = redis.connect('127.0.0.1', 6379)
    db  = modis.connect(red)
  end)
  after_each(function()
    db:dropDatabase()
    red:quit()
  end)

  describe('db', function()
    describe(':getCollectionNames', function()
      it('is initially empty', function()
        assert.same({}, db:getCollectionNames())
      end)
      it('returns the created collections', function()
        db:createCollection('users')
        db:createCollection('projects')
        assert.same({'projects', 'users'}, db:getCollectionNames())
      end)
    end)

    describe(':getCollection', function()
      describe('when the collection does not exist', function()
        it('does not return the same reference when called twice', function()
          assert.not_equal(db:getCollection('users'), db:getCollection('users'))
        end)
      end)
      describe('when the collection exists', function()
        it('returns the same reference when called twice', function()
          db:createCollection('users')
          assert.equal(db:getCollection('users'), db:getCollection('users'))
        end)
      end)
    end)

    describe('.<collectionname>', function()
      describe('when the collection does not exist', function()
        it('does not return the same reference when called twice', function()
          assert.not_equal(db.users, db.users)
        end)
      end)
      describe('when the collection exists', function()
        it('returns the same reference when called twice', function()
          db:createCollection('users')
          assert.equal(db.users, db.users)
        end)
      end)
    end)

    describe('when there is another database with the same name', function()
      local db2
      before_each(function()
        db2 = modis.connect(red)
      end)
      it('can have items added via the other db', function()
        db2.users:insert({})
        assert.equal(1, db.users:count())
      end)
      it('can have collections created by the other db', function()
        db2:createCollection('users')
        assert.is_true(db.users:exists())
      end)
      it('can be dropped by the other db', function()
        db:createCollection('users')
        db2:dropDatabase()
        assert.is_false(db.users:exists())
      end)
    end)
  end) -- DB

  describe('Collection', function()

    describe(':exists', function()
      describe('when nothing has been done on the table', function()
        it('returns false', function()
          assert.is_false(db.users:exists())
        end)
      end)
      describe('when the table has been created with createCollection', function()
        it('returns true', function()
          db:createCollection('users')
          assert.is_true(db.users:exists())
        end)
      end)
    end)

    describe(':count', function()
      it('starts at 0', function()
        assert.equals(0, db.users:count())
      end)
    end)

    describe(':insert', function()
      it('marks the table as existing', function()
        db.users:insert({})
        assert.is_true(db.users:exists())
      end)
      it('increases the count', function()
        for i=1,3 do db.users:insert({}) end
        assert.equals(3, db.users:count())
      end)
      it('adds an _id field if the object does not have it', function()
        local u = db.users:insert({name = 'joey'})
        assert.same(u, {name = 'joey', _id = 1})
      end)
    end)

    describe(':find', function()
      it('returns all elements when the criteria is empty', function()
        for i=1,3 do db.users:insert({}) end
        assert.equals(#db.users:find({}), 3)
      end)
      it('returns an item given its id', function()
        local u = db.users:insert({name = 'joey'})
        assert.same({u}, db.users:find({_id = u._id}))
      end)
    end)


  end)
end)

