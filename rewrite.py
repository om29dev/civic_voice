import re

with open(r'c:\Users\MADHAV\Downloads\Civic Voice\civic_voice\lib\core\services\form_filler_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add optionalDocuments to GovernmentFormDef class
class_def_old = '''class GovernmentFormDef {
  final String serviceId;
  final String formName;
  final String formNameHindi;
  final String officialUrl;
  final List<FormFieldDef> fields;
  final List<DocumentType> requiredDocuments;
  final String submitInstructions;

  const GovernmentFormDef({
    required this.serviceId,
    required this.formName,
    required this.formNameHindi,
    required this.officialUrl,
    required this.fields,
    required this.requiredDocuments,
    required this.submitInstructions,
  });
}'''

class_def_new = '''class GovernmentFormDef {
  final String serviceId;
  final String formName;
  final String formNameHindi;
  final String officialUrl;
  final List<FormFieldDef> fields;
  final List<DocumentType> requiredDocuments;
  final List<DocumentType> optionalDocuments;
  final String submitInstructions;

  const GovernmentFormDef({
    required this.serviceId,
    required this.formName,
    required this.formNameHindi,
    required this.officialUrl,
    required this.fields,
    this.requiredDocuments = const [],
    this.optionalDocuments = const [],
    required this.submitInstructions,
  });
}'''
content = content.replace(class_def_old, class_def_new)

# 2. Modify definitions in the _forms map
blocks = content.split('GovernmentFormDef(')
new_blocks = [blocks[0]]

for block in blocks[1:]:
    # Extract requiredDocuments array if it exists
    req_docs_match = re.search(r'requiredDocuments:\s*\[(.*?)\],', block, re.DOTALL)
    if req_docs_match:
        docs_str = req_docs_match.group(1)
        docs = [d.strip() for d in docs_str.split(',') if d.strip()]
        
        compulsory = []
        optional = []
        for d in docs:
            if 'aadhaar' in d.lower() or 'pan' in d.lower():
                compulsory.append(d)
            else:
                optional.append(d)
        
        replacement = ""
        if compulsory:
            replacement += f"requiredDocuments: [{', '.join(compulsory)}],\n      "
        if optional:
            replacement += f"optionalDocuments: [{', '.join(optional)}],"
        
        if replacement:
            block = block.replace(req_docs_match.group(0), replacement)
        else:
            block = block.replace(req_docs_match.group(0), "")

    # Modify fields so that anything that isn't Aadhaar or PAN is optional
    def field_replace(match):
        inner = match.group(1)
        inner = re.sub(r',\s*isRequired:\s*(true|false)', '', inner)
        
        is_compulsory = False
        if "aadhaar" in inner.lower() or "pan" in inner.lower():
            is_compulsory = True
            
        if not is_compulsory:
            inner += ", isRequired: false"
            
        return f"FormFieldDef({inner})"
        
    block = re.sub(r'FormFieldDef\((.*?)\)', field_replace, block)
    new_blocks.append(block)

new_content = 'GovernmentFormDef('.join(new_blocks)

with open(r'c:\Users\MADHAV\Downloads\Civic Voice\civic_voice\lib\core\services\form_filler_service.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Done rewrite")
