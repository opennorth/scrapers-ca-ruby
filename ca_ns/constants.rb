ROLES = [
  'administrator',
  'chairman',
  'assistant clerk',
  'clerk',
  'lieutenant governor',
  'sergeant-at-arms',
  'speaker',
  'premier',
]

# Names are not linked if there are errors in the given name or family name, if
# the honorary prefix is missing, unabbreviated or missing a period, or if the
# name is of a role.
TYPOS = {
  "christopher d'entromont" => 'http://nslegislature.ca/index.php/people/members/christopher_a_dentremont1', # family name
  "d'enteremont" => 'http://nslegislature.ca/index.php/people/members/christopher_a_dentremont1', # family name
  "d'entremount" => 'http://nslegislature.ca/index.php/people/members/christopher_a_dentremont1', # family name
  'bekcy kent' => 'http://nslegislature.ca/index.php/people/members/Becky_Kent', # given name
  'diane whalen' => 'http://nslegislature.ca/index.php/people/members/diana_whalen1', # given name
  'gordon gosse' => 'http://nslegislature.ca/index.php/people/members/gordie_gosse1', # given name
  'harold therault' => 'http://nslegislature.ca/index.php/people/members/Harold_Theriault', # family name
  'jaimie baillie' => 'http://nslegislature.ca/index.php/people/members/jamie_baillie', # given name
  'mailyn more' => 'http://nslegislature.ca/index.php/people/members/Marilyn_More', # given name
  'mariyln more' => 'http://nslegislature.ca/index.php/people/members/Marilyn_More', # given name
  'maureen macdonld' => 'http://nslegislature.ca/index.php/people/members/Maureen_MacDonald', # family name
  'michael samson' => 'http://nslegislature.ca/index.php/people/members/michel_p_samson1', # given name
  'michele raymond' => 'http://nslegislature.ca/index.php/people/members/Michele_Raymond', # unlinked occurs before linked
  'pan eyking' => 'http://nslegislature.ca/index.php/people/members/pam_eyking', # given name
  'peterson-rayfuse' => 'http://nslegislature.ca/index.php/people/members/Denise_Peterson-Rafuse', # family name
  'ross laundry' => 'http://nslegislature.ca/index.php/people/members/Ross_Landry', # family name
  'macneil' => 'http://nslegislature.ca/index.php/people/members/Stephen_McNeil', # family name
  'stephen macneil' => 'http://nslegislature.ca/index.php/people/members/Stephen_McNeil', # family name
  'bellieveau' => 'http://nslegislature.ca/index.php/people/members/sterling_belliveau1', # family name
  'sterling bellieau' => 'http://nslegislature.ca/index.php/people/members/sterling_belliveau1', # family name
  'sterling bellieveau' => 'http://nslegislature.ca/index.php/people/members/sterling_belliveau1', # family name
  'sterlng belliveau' => 'http://nslegislature.ca/index.php/people/members/sterling_belliveau1', # given name
  'the lieutenant governor' => 'http://nslegislature.ca/index.php/people/lt-gov/', # role-based
  'vickie conrad' => 'http://nslegislature.ca/index.php/people/members/Vicki_Conrad', # given name
  'william estabooks' => 'http://nslegislature.ca/index.php/people/members/Bill_Estabrooks', # both names
}

HEADING_TYPOS = {
  'MOTIONS UNDER RULE 5(5)' => 'MOTION UNDER RULE 5(5)',
  'NOTICE OF QUESTION FOR WRITTEN ANSWERS' => 'NOTICE OF QUESTIONS FOR WRITTEN ANSWERS',
  'NOTICES OF MOTION UNDER RULE (32)(3)' => 'NOTICES OF MOTION UNDER RULE 32(3)',
  "OPPOSTION MEMBERS' BUSINESS" => "OPPOSITION MEMBERS' BUSINESS",
  'ORAL QUESTION PUT BY MEMBERS' => 'ORAL QUESTIONS PUT BY MEMBERS',
  'Pursuant to Rule 30' => 'PURSUANT TO RULE 30',
  'Pursuant to Rule 30(1)' => 'PURSUANT TO RULE 30(1)',
  'PRESENTING REPORT OF COMMITTEES' => 'PRESENTING REPORTS OF COMMITTEES',
  'PRESENTING REPORTS OF COMMIITTEES' => 'PRESENTING REPORTS OF COMMITTEES',
  'PRESENTING REPORTS OF COMMITEES' => 'PRESENTING REPORTS OF COMMITTEES',
  'Private and Local Bills For Third Reading' => 'PRIVATE AND LOCAL BILLS FOR THIRD READING',
  'TABLING REPORTS, REGLATIONS AND OTHER PAPERS' => 'TABLING REPORTS, REGULATIONS AND OTHER PAPERS',
  /\AQUESTION No\b/ => 'QUESTION NO',
  /\ARESOLTUION\b/ => 'RESOLUTION',
  /\ARESOLTUTION\b/ => 'RESOLUTION',
  /\ARESOLUION\b/ => 'RESOLUTION',
  /\ARESOLUTION (?=\d)/ => 'RESOLUTION NO. ',
  /\ARESOLUTION NO.(?! )/ => 'RESOLUTION NO. ',
  /\ARESOLUTIONNO\b/ => 'RESOLUTION NO',
  /\ARESOLUTIONS NO\b/ => 'RESOLUTION NO',
  /\ARESOLUTON\b/ => 'RESOLUTION',
}

TOP_LEVEL_HEADINGS = [
  'ADJOURNMENT',
  'ANSWERS TO WRITTEN QUESTIONS',
  'GOVERNMENT BUSINESS',
  'GOVERNMENT MOTIONS', # frequent child of "GOVERNMENT BUSINESS"
  'GOVERNMENT NOTICES OF MOTION',
  'INTRODUCTION OF BILLS',
  'MOTION UNDER RULE 43', # frequent child of "ADJOURNMENT"
  'MOTION UNDER RULE 5(5)', # frequent child of "ADJOURNMENT"
  'MOTIONS OTHER THAN GOVERNMENT MOTIONS', # frequent child of "OPPOSITION MEMBERS' BUSINESS"
  'NOTICE OF QUESTIONS FOR WRITTEN ANSWERS',
  'NOTICES OF MOTION',
  'NOTICES OF MOTION UNDER RULE 32(3)',
  "OPPOSITION MEMBERS' BUSINESS",
  'ORAL QUESTIONS PUT BY MEMBERS',
  'ORAL QUESTIONS PUT BY MEMBERS TO MINISTERS',
  'ORDERS OF THE DAY', # frequently precedes "GOVERNMENT BUSINESS"
  'PRESENTING AND READING PETITIONS',
  'PRESENTING REPORTS OF COMMITTEES',
  'PRIVATE AND LOCAL BILLS FOR SECOND READING',
  'PRIVATE AND LOCAL BILLS FOR THIRD READING',
  "PRIVATE MEMBERS' PUBLIC BILLS FOR SECOND READING",
  "PRIVATE MEMBERS' PUBLIC BILLS FOR THIRD READING",
  'PUBLIC BILLS FOR SECOND READING',
  'PUBLIC BILLS FOR THIRD READING',
  'STATEMENTS BY MINISTERS',
  'TABLING REPORTS, REGULATIONS AND OTHER PAPERS',
]

HEADING_TO_TAG = {
  'ADJOURNMENT' => :adjournment,
  'ANSWERS TO WRITTEN QUESTIONS' => :questions,
  # 'GOVERNMENT BUSINESS',
  # 'GOVERNMENT MOTIONS',
  'GOVERNMENT NOTICES OF MOTION' => :noticesOfMotion,
  # 'INTRODUCTION OF BILLS',
  # 'MOTION UNDER RULE 43',
  # 'MOTION UNDER RULE 5(5)',
  # 'MOTIONS OTHER THAN GOVERNMENT MOTIONS',
  'NOTICE OF QUESTIONS FOR WRITTEN ANSWERS' => :questions,
  'NOTICES OF MOTION' => :noticesOfMotion,
  'NOTICES OF MOTION UNDER RULE 32(3)' => :noticesOfMotion,
  # "OPPOSITION MEMBERS' BUSINESS",
  'ORAL QUESTIONS PUT BY MEMBERS' => :questions,
  'ORAL QUESTIONS PUT BY MEMBERS TO MINISTERS' => :questions,
  # 'ORDERS OF THE DAY',
  'PRESENTING AND READING PETITIONS' => :petitions,
  'PRESENTING REPORTS OF COMMITTEES' => :papers,
  # 'PRIVATE AND LOCAL BILLS FOR SECOND READING',
  # 'PRIVATE AND LOCAL BILLS FOR THIRD READING',
  # "PRIVATE MEMBERS' PUBLIC BILLS FOR SECOND READING",
  # "PRIVATE MEMBERS' PUBLIC BILLS FOR THIRD READING",
  # 'PUBLIC BILLS FOR SECOND READING',
  # 'PUBLIC BILLS FOR THIRD READING',
  'STATEMENTS BY MINISTERS' => :ministerialStatements,
  'TABLING REPORTS, REGULATIONS AND OTHER PAPERS' => :papers,
}

HEADINGS = TOP_LEVEL_HEADINGS + [
  # Subheadings of "NOTICE OF QUESTIONS FOR WRITTEN ANSWERS"
  'PURSUANT TO RULE 30',
  'PURSUANT TO RULE 30(1)',
  'RESPONSE:',
  'RESPONSES',
  # All-caps headings with no useful markers.
  'COLLABORATIVE EMERGENCY CENTRES',
  'ELIGIBILITY BREAKDOWN',
  'INQUIRY TERMS OF REF.',
  'INTL. DAY FOR ELIMINATION OF VIOLENCE AGAINST WOMEN',
  'ON MOTION FOR SUPPLY',
  'RESPONSIBILITY ASSUME',
]

HEADINGS_RE = [
  /\ABill No\. \d+ [–-]/, # n-dash
  /\AQUESTION NO\. \d+\z/,
  /\ARESOLUTION NO\. \d+\z/,
  /\AGiven on \S+ \d{1,2}, 20\d\d\z/,
  /\ATabled \S+ \d{1,2}, 20\d\d\z/,
  # Issue-based headings that have no useful markers.
  # EMO: ASPY BAY/ST. MARGARETS VILLAGE/BAY ST. LAWRENCE
  # ERDT: ACADIANS (N.S.)
  # GAMING: HAMMONDS PLAINS GAMING CTR.
  # JUSTICE: N.S. HOME FOR COLORED CHILDREN -
  # N.S. HOME FOR COLORED CHILDREN:
  # PREM: FIRST CONTRACT ARBITRATION/UNIONIZATION RATE:
  # SNSMR: SALVATION ARMY GOOD NEIGHBOUR FUND
  # STATUS OF WOMEN: DOMESTIC VIOLENCE ACTION PLAN
  /\A(?:EMO|ERDT|GAMING|JUSTICE|N\.S\. HOME FOR COLORED CHILDREN|PREM|SNSMR|STATUS OF WOMEN)\b/,
]
