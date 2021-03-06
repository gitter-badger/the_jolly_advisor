class CourseInstance < ActiveRecord::Base
  belongs_to :semester
  belongs_to :course
  belongs_to :professor
  has_many :meetings, dependent: :destroy
  has_many :enrollments, dependent: :destroy
  has_many :enrolled_students, through: :enrollments, source: :user

  scope :ongoing, ->(date) {
    where('? BETWEEN course_instances.start_date AND course_instances.end_date', date)
  }
  scope :unenrolled, ->(user) {
    where(%{NOT EXISTS (SELECT enrollments.id FROM enrollments WHERE
          enrollments.course_instance_id = course_instances.id AND enrollments.user_id = ?)},
          user.id)
  }
  scope :search, ->(term, user, date) {
    includes(:course, :meetings)
      .ongoing(date)
      .joins(:course)
      .where(%{concat(lower(courses.department), courses.course_number) like ?
              OR lower(courses.title) like ?},
             "%#{term.to_s.downcase.gsub(/\s+/, '')}%", "%#{term.to_s.downcase}%")
      .unenrolled(user)
  }

  def schedule
    return 'TBA' if meetings.blank?
    meetings.map(&:schedule).join '; '
  end

  def schedulable?
    end_date > Date.today
  end
end
