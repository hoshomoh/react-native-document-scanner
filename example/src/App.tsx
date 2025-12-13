import * as React from 'react';
import {
  StyleSheet,
  ScrollView,
  Image,
  SafeAreaView,
  Text,
  View,
  TouchableOpacity,
  Switch,
  TextInput,
} from 'react-native';
import {
  scanDocuments,
  type ScanResult,
  type ScanOptions,
} from '@hoshomoh/react-native-document-scanner';

type FilterType = 'color' | 'grayscale' | 'monochrome';
type FormatType = 'jpg' | 'png';

/* Helper Components - defined outside App to prevent re-creation on render */
const OptionRow = ({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) => (
  <View style={styles.optionRow}>
    <Text style={styles.optionLabel}>{label}</Text>
    {children}
  </View>
);

function SegmentedControl<T extends string>({
  values,
  selected,
  onSelect,
}: {
  values: T[];
  selected: T;
  onSelect: (v: T) => void;
}) {
  return (
    <View style={styles.segmentedControl}>
      {values.map((value) => (
        <TouchableOpacity
          key={value}
          style={[
            styles.segmentButton,
            selected === value && styles.segmentButtonActive,
          ]}
          onPress={() => onSelect(value)}
        >
          <Text
            style={[
              styles.segmentText,
              selected === value && styles.segmentTextActive,
            ]}
          >
            {value}
          </Text>
        </TouchableOpacity>
      ))}
    </View>
  );
}

export default function App() {
  const [results, setResults] = React.useState<ScanResult[]>([]);

  /* Options State */
  const [maxPageCount, setMaxPageCount] = React.useState('5');
  const [quality, setQuality] = React.useState('0.8');
  const [format, setFormat] = React.useState<FormatType>('jpg');
  const [filter, setFilter] = React.useState<FilterType>('color');
  const [includeBase64, setIncludeBase64] = React.useState(false);
  const [includeText, setIncludeText] = React.useState(false);

  const handleScan = async () => {
    const options: ScanOptions = {
      maxPageCount: parseInt(maxPageCount, 10) || 5,
      quality: parseFloat(quality) || 0.8,
      format,
      filter,
      includeBase64,
      includeText,
    };

    console.log('Scanning with options:', options);

    try {
      const scannedResults = await scanDocuments(options);
      console.log('Scanned Results:', scannedResults);
      setResults(scannedResults);
    } catch (e: any) {
      console.error('Scan failed:', e);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Options Panel */}
      <View style={styles.optionsPanel}>
        <Text style={styles.panelTitle}>Scan Options</Text>

        <OptionRow label="Max Pages">
          <TextInput
            style={styles.textInput}
            value={maxPageCount}
            onChangeText={setMaxPageCount}
            keyboardType="number-pad"
            placeholder="5"
          />
        </OptionRow>

        <OptionRow label="Quality">
          <TextInput
            style={styles.textInput}
            value={quality}
            onChangeText={setQuality}
            keyboardType="decimal-pad"
            placeholder="0.8"
          />
        </OptionRow>

        <OptionRow label="Format">
          <SegmentedControl
            values={['jpg', 'png'] as FormatType[]}
            selected={format}
            onSelect={setFormat}
          />
        </OptionRow>

        <OptionRow label="Filter">
          <SegmentedControl
            values={['color', 'grayscale', 'monochrome'] as FilterType[]}
            selected={filter}
            onSelect={setFilter}
          />
        </OptionRow>

        <OptionRow label="Include Base64">
          <Switch value={includeBase64} onValueChange={setIncludeBase64} />
        </OptionRow>

        <OptionRow label="Include Text (OCR)">
          <Switch value={includeText} onValueChange={setIncludeText} />
        </OptionRow>

        {/* Scan Button */}
        <TouchableOpacity style={styles.scanButton} onPress={handleScan}>
          <Text style={styles.scanButtonText}>📷 Scan Document</Text>
        </TouchableOpacity>
      </View>

      {/* Results */}
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {results.length === 0 && (
          <Text style={styles.placeholder}>
            No scans yet. Configure options and tap Scan.
          </Text>
        )}
        {results.map((result, index) => (
          <View key={index} style={styles.pageContainer}>
            <Text style={styles.pageTitle}>Page {index + 1}</Text>

            {/* Image */}
            {result.uri && (
              <Image
                source={{ uri: result.uri }}
                style={styles.image}
                resizeMode="contain"
              />
            )}

            {/* OCR Text */}
            {result.text && (
              <View style={styles.sectionContainer}>
                <Text style={styles.sectionTitle}>Extracted Text:</Text>
                <View style={styles.textWrapper}>
                  <Text selectable style={styles.textContent}>
                    {result.text}
                  </Text>
                </View>
              </View>
            )}

            {/* Metadata Blocks */}
            {result.blocks && result.blocks.length > 0 && (
              <View style={styles.sectionContainer}>
                <Text style={styles.sectionTitle}>Metadata Blocks:</Text>
                <View style={styles.codeWrapper}>
                  <Text selectable style={styles.codeContent}>
                    {JSON.stringify(result.blocks, null, 2)}
                  </Text>
                </View>
              </View>
            )}
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  optionsPanel: {
    backgroundColor: '#fff',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#ddd',
  },
  panelTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 12,
  },
  optionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  optionLabel: {
    fontSize: 14,
    color: '#333',
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 6,
    paddingHorizontal: 10,
    paddingVertical: 6,
    width: 80,
    textAlign: 'center',
    fontSize: 14,
  },
  segmentedControl: {
    flexDirection: 'row',
    borderRadius: 6,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#007AFF',
  },
  segmentButton: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: '#fff',
  },
  segmentButtonActive: {
    backgroundColor: '#007AFF',
  },
  segmentText: {
    fontSize: 12,
    color: '#007AFF',
  },
  segmentTextActive: {
    color: '#fff',
  },
  scanButton: {
    backgroundColor: '#007AFF',
    paddingVertical: 14,
    borderRadius: 10,
    marginTop: 10,
    alignItems: 'center',
  },
  scanButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  scrollContent: {
    alignItems: 'center',
    padding: 20,
    paddingBottom: 100,
  },
  placeholder: {
    fontSize: 14,
    color: '#888',
    marginTop: 40,
  },
  pageContainer: {
    width: '100%',
    marginBottom: 30,
    borderBottomWidth: 1,
    borderBottomColor: '#ddd',
    paddingBottom: 20,
    alignItems: 'center',
  },
  pageTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  image: {
    width: 300,
    height: 400,
    marginVertical: 10,
    backgroundColor: '#eee',
    borderRadius: 8,
  },
  sectionContainer: {
    width: '100%',
    marginTop: 15,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 5,
    color: '#333',
  },
  textWrapper: {
    backgroundColor: '#f5f5f5',
    padding: 10,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#e0e0e0',
  },
  textContent: {
    fontSize: 14,
    fontFamily: 'Courier',
    color: '#000',
  },
  codeWrapper: {
    backgroundColor: '#1e1e1e',
    padding: 10,
    borderRadius: 8,
  },
  codeContent: {
    fontSize: 10,
    fontFamily: 'Courier New',
    color: '#00ff00',
  },
});
