require 'rubygems'
require 'thor'

ROOT_NOTES = ['A', 'B', 'C', 'D', 'E', 'F', 'G']

SEMITONES = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B'
]

MAJOR_INTERVALS = [2, 4, 5, 7, 9, 11, 12]
MINOR_INTERVALS = [2, 3, 5, 7, 8, 10, 12]

ROMAN_TO_INT = {
    i: 1,
    v: 5,
    x: 10,
    l: 50,
    c: 100,
    d: 500,
    m: 1000
}

MAJOR_CHORD_ROMAN_NUMBERS = ['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii']
MINOR_CHORD_ROMAN_NUMBERS = ['i', 'ii', 'III', 'iv', 'v', 'VI', 'VII']

class ChordMaker < Thor
  desc "notes_in_key KEY_NAME", "print the notes for the given key"
  def notes_in_key(key_name)
    puts key_notes(key_name).join(' ')
  end

  desc "notes_in_chord KEY_NAME CHORD_NUMBER", "print the notes in the chord number for a given key"
  def notes_in_chord(key_name, chord_number)
    if chord_number.to_i == 0
      chord_number = roman_to_int(chord_number)
    else
      chord_number = chord_number.to_i
    end
    raise 'Chord numbers must be between i (1) and vii (7)' unless chord_number.between?(1, 7)

    notes = chord_notes(key_name, chord_number.to_i)
    type = key_type(key_name)[:type]
    roman_numbers = type == :major ? MAJOR_CHORD_ROMAN_NUMBERS : MINOR_CHORD_ROMAN_NUMBERS

    puts "#{key_name} (#{roman_numbers[chord_number - 1]}): #{notes[0]} #{chord_type_from_intervals(notes)}: #{notes.join(' ')}"
  end

  desc "major_keys", "print notes for all major keys"
  def major_keys
    SEMITONES.each do |key|
      print "#{key}: "
      notes_for_key(key)
    end
  end

  desc "minor_keys", "print notes for all minor keys"
  def minor_keys
    SEMITONES.each do |key|
      print "#{key} minor: "
      notes_for_key(key + 'min')
    end
  end

  private
  def key_notes(keyname)
    key_type = key_type(keyname)

    root_index = SEMITONES.index(key_type[:root])
    raise 'Root note is invalid' if root_index.nil?

    note_numbers = key_type[:intervals].map{|idx| root_index + idx}.rotate(6)
    key_notes = []
    note_numbers.each_with_index do |number, idx|
      name = note_name_from_number(number)
      if idx > 0
        unless are_sequential(key_notes[idx - 1], name)
          name = correct_sequence(name)
        end
      end

      key_notes.push name
    end

    key_notes
  end

  def key_type(keyname)
    key_type = :major
    intervals = MAJOR_INTERVALS
    match = keyname.match(/([A-G])(b|#)?(maj|min)?$/)
    raise "Invalid key name" if match.nil?
    root = match[1] + match[2].to_s

    if type = match[3]
      case type
        when 'min'
          key_type = :minor
          intervals = MINOR_INTERVALS
        when 'maj'
        else
          raise "Unknown key type #{type}"
      end
    end

    {type: key_type, intervals: intervals, root: root}
  end

  def chord_notes(key_name, chord_number)
    key_notes = key_notes(key_name)
    root = key_notes[chord_number - 1]
    third_index = chord_number + 1 > 6 ? chord_number - 6 : chord_number + 1
    fifth_index = chord_number + 3 > 6 ? chord_number - 4 : chord_number + 3
    [root, key_notes[third_index], key_notes[fifth_index]]
  end

  def are_sequential(note_1, note_2)
    index_1 = ROOT_NOTES.index(note_1[0])
    index_2 = ROOT_NOTES.index(note_2[0])

    index_2 = index_2 < index_1 ? index_2 + 7 : index_2
    index_2 - index_1 == 1
  end

  def is_flat(note)
    note.match(/([a-gA-G])b/)
  end

  def is_sharp(note)
    note.match(/([a-gA-G])\#/)
  end

  def flatten(note)
    adjust(note, -1)
  end

  def sharpen(note)
    adjust(note, 1)
  end

  def adjust(note, semitones)
    index = SEMITONES.index(note)
    raise 'Note not found' if index.nil?

    adjusted_index = index + semitones
    if adjusted_index < 0
      adjusted_index += 12
    elsif adjusted_index > 11
      adjusted_index -= 12
    end

    SEMITONES[adjusted_index]
  end

  def correct_sequence(note)
    root = note[0]
    if is_flat(note)
      root_index = ROOT_NOTES.index(root) == 0 ? 7 : ROOT_NOTES.index(root)
      ROOT_NOTES[root_index - 1] + '#'
    else
      root_index = ROOT_NOTES.index(root) == 7 ? 0 : ROOT_NOTES.index(root)
      ROOT_NOTES[root_index + 1] + 'b'
    end
  end

  def chord_type_from_intervals(intervals)
    raise 'Chord intervals must have three elements' unless intervals.size == 3

    root = note_number_from_name(intervals[0])
    third = note_number_from_name(intervals[1])
    fifth = note_number_from_name(intervals[2])

    if third < root
      third += 12
      fifth += 12
    end

    if fifth < third
      fifth += 12
    end

    type = 'unknown'
    if (third - root == 4) && (fifth - third == 3)
      type = 'major'
    elsif (third - root == 3) && (fifth - third == 4)
      type = 'minor'
    elsif (third - root == 3) && (fifth - third == 3)
      type = 'diminished'
    end

    type
  end

  def note_number_from_name(name)
    if match = is_sharp(name)
      base_note = match[1]
      index = SEMITONES.index(base_note) + 1
      base_note_index = index == 12 ? 0 : index
      name = SEMITONES[base_note_index]
    end

    index = SEMITONES.index(name)
    raise "No note with name #{name}" if index.nil?
    index
  end

  def note_name_from_number(number)
    number = number > 11 ? number - 12 : number
    raise "Note number #{number} out of range" if number < 0 or number > 11

    SEMITONES[number]
  end

  def roman_to_int(roman)
    numbers = roman.downcase.chars.map { |char| ROMAN_TO_INT[char.to_sym] }.reverse
    numbers.inject([0, 1]) do |result_number, int|
      result, number = result_number
      int >= number ? [result + int, int] : [result - int, number]
    end.first
  end
end

ChordMaker.start