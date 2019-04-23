require 'sqlite3'
require 'singleton'

class QuestionsDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class Users

    attr_accessor :fname, :lname, :id

    def self.find_by_name(fname, lname)
         user = QuestionsDBConnection.instance.execute(<<-SQL, fname, lname)
            SELECT
                *
            FROM
                users
            WHERE
                fname = ? AND lname = ?
        SQL
        return nil unless user.length > 0
        Users.new(user.first)
    end

    def self.find_by_id(id)
        user = QuestionsDBConnection.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                users
            WHERE
                users.id = ?
        SQL
        return nil unless user.length > 0
        Users.new(user.first)
    end

    
    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end
    
    def average_karma
        likes = QuestionsDBConnection.instance.execute(<<-SQL, id)
            SELECT
                COUNT(question_likes.user_id) / COUNT(DISTINCT(questions.author_id))
            FROM
                users
            JOIN
                questions ON users.id = questions.author_id
            JOIN
                question_likes ON question_likes.question_id = questions.id
            WHERE
                users.id = ?
        SQL
        likes.first
    end

    def liked_questions
        Question_likes.liked_questions_for_user_id(self.id)
    end

    def followed_questions
        Questions_follows.followed_questions_for_user_id(self.id)
    end
    
    def authored_questions
        fname = self.fname
        quest = QuestionsDBConnection.instance.execute(<<-SQL, fname)
            SELECT
                *
            FROM
                questions
            JOIN
                users ON questions.author_id = users.id
            WHERE
                fname = ?
        SQL
        return nil unless quest.length > 0
        quest.map { |q| Questions.new(q) }     
    end

    def authored_replies
        fname = self.fname
        quest = QuestionsDBConnection.instance.execute(<<-SQL, fname)
            SELECT
                *
            FROM
                replies 
            JOIN
                users ON replies.user_id = users.id
            WHERE
                fname = ?
        SQL
        return nil unless quest.length > 0
        quest.map { |q| Questions.new(q) }     
    end
end

class Questions

    attr_accessor :title, :body, :id, :author_id

    def self.find_by_id(id)
        quest = QuestionsDBConnection.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                questions 
            WHERE
                questions.id = ?
        SQL
        return nil unless quest.length > 0
        Questions.new(quest.first)
    end
    

    def self.find_by_author_id(author_id)
        quest = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
            SELECT
                *
            FROM
                questions 
            WHERE
                questions.author_id = ?
        SQL
        return nil unless quest.length > 0
        Questions.new(quest.first)
    end

    def self.most_followed(n)
        Questions_follows.most_followed_questions(n)
    end

    def self.most_liked(n)
        Question_likes.most_liked_questions(n)
    end

    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @author_id = options['author_id']
    end

    def likers
        Question_likes.likers_for_question_id(self.id)
    end

    def num_likes
        Question_likes.num_likes_for_question_id(self.id)
    end



    def followers
        Questions_follows.followers_for_question_id(self.id)
    end
    
    def author
        me = self.id
        quest = QuestionsDBConnection.instance.execute(<<-SQL, me)
            SELECT
                fname
            FROM
                questions 
            JOIN users ON users.id = author_id
            WHERE
                questions.id = ?
        SQL
        return nil unless quest.length > 0
        quest.first
    end

    def replies
        me = self.id
        quest = QuestionsDBConnection.instance.execute(<<-SQL, me)
            SELECT
                *
            FROM
                replies 
            -- JOIN questions ON questions.id = question_id
            WHERE
                question_id = ?
        SQL
        return nil unless quest.length > 0
        quest.map { |r| Replies.new(r) }
    end
end


class Questions_follows

    def self.find_by_id(id)
        quest_follow = QuestionsDBConnection.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                questions_follows 
            WHERE
                questions_follows.id = ?
        SQL
        return nil unless quest_follow.length > 0
        Questions_follows.new(quest_follow.first)
    end

    def self.followers_for_question_id(question_id)
        users = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
            SELECT
                *
            FROM
                users
            JOIN 
                questions_follows ON users.id = user_id
            WHERE
                question_id = ?
        SQL
        users.map {|user| Users.new(user)}
    end

    def self.most_followed_questions(n)
        fol_ques = QuestionsDBConnection.instance.execute(<<-SQL, n)
        SELECT
            * 
        FROM
            questions
        JOIN 
            Questions_follows ON questions.id = question_id
        GROUP BY
            title
        ORDER BY COUNT(title) DESC
        LIMIT ?
        SQL
        fol_ques.map {|q| Questions.new(q)}
    end

    def self.followed_questions_for_user_id(user_id)
        quest = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
            SELECT
                *
            FROM
                questions
            JOIN 
                questions_follows ON questions.id = question_id
            WHERE
                question_id = ?
        SQL
        quest.map {|q| Questions.new(q)}
    end

    def initialize(options)
        @id = options['id']
        @user_id = options['user_id']
        @question_id = options['question_id']
    end
    
end


class Replies

    attr_accessor :body, :user_id, :id , :question_id , :parent_reply_id

    def self.find_by_id(id)
        reply = QuestionsDBConnection.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                replies 
            WHERE
                replies.id = ?
        SQL
        return nil unless reply.length > 0
        Replies.new(reply.first)
    end

    def self.find_by_user_id(user_id)
        reply = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
            SELECT
                *
            FROM
                replies 
            WHERE
                replies.user_id = ?
        SQL
        return nil unless reply.length > 0
        Replies.new(reply.first)
    end

    def self.find_by_question_id(question_id)
        reply = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
            SELECT
                *
            FROM
                replies 
            WHERE
                replies.question_id = ?
        SQL
        return nil unless reply.length > 0
        Replies.new(reply.first)
    end       

    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @parent_reply_id = options['parent_reply_id']
        @user_id = options['user_id']
        @body = options['body']
    end

    def author
        user = self.id
        auth = QuestionsDBConnection.instance.execute(<<-SQL, user)
            SELECT
                fname
            FROM
                users 
            WHERE
                users.id = ?
        SQL
        return nil unless auth.length > 0
        auth.first  
    end

     def question
        q_id = self.question_id
        quest = QuestionsDBConnection.instance.execute(<<-SQL, q_id)
            SELECT
                *
            FROM
                questions 
            WHERE
                questions.id = ?
        SQL
        return nil unless quest.length > 0
        Questions.new(quest.first)  
    end

    def parent_reply
        p_rep_id = self.parent_reply_id
        p_reply = QuestionsDBConnection.instance.execute(<<-SQL, p_rep_id)
            SELECT
                *
            FROM
                replies 
            WHERE
                replies.id = ?
        SQL
        return nil unless p_reply.length > 0
        Replies.new(p_reply.first)  
    end

     def child_reply
        reply = QuestionsDBConnection.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                replies 
            WHERE
                parent_reply_id = ?
        SQL
        return nil unless reply.length > 0
        reply.map{|r|Replies.new(r)}

    end


end

class Question_likes

    def self.find_by_id(id)
        quest_like = QuestionsDBConnection.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                question_likes 
            WHERE
                question_likes.id = ?
        SQL
        return nil unless quest_like.length > 0
        Question_likes.new(quest_like.first)
    end

    def self.likers_for_question_id(question_id)
        likers = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
            SELECT
                *
            FROM
                users
            JOIN
                question_likes ON users.id = user_id
            JOIN
                questions ON questions.id = question_id
            WHERE
                questions.id = ?
        SQL
        likers.map {|liker| Users.new(liker) }
    end

    def self.num_likes_for_question_id(question_id)
        num_likes = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
            SELECT
                COUNT(user_id)
            FROM
                question_likes
            WHERE
                question_id = ?
        SQL
        num_likes.first.values.first
    end

    def self.liked_questions_for_user_id(user_id)
        liked_quests = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
            SELECT
                *
            FROM
                questions
            JOIN
                question_likes ON questions.id = question_id
            WHERE
                user_id = ?
        SQL
        liked_quests.map {|q| Questions.new(q) }
    end

    def self.most_liked_questions(n)
        most = QuestionsDBConnection.instance.execute(<<-SQL, n)
            SELECT
                * 
            FROM
                questions
            JOIN 
                question_likes ON questions.id = question_id
            GROUP BY
                title
            ORDER BY COUNT(title) DESC
            LIMIT ?
        SQL
        most.map {|m| Questions.new(m)}
    end

    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @user_id = options['user_id']
    end
end
